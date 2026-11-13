from __future__ import annotations
from typing import Any, Dict, List, Optional, Tuple
import secrets
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .auth import (
    create_access_token,
    hash_password,
    hash_token,
    require_auth,
    require_teacher,
    verify_password,
)
from .database import get_db
from .insights import analyze_class_events, analyze_student_events, maybe_enrich_with_llm
from .models import APIToken, AnswerEvent, SchoolClass, Student, Teacher
from .schemas import (
    AnswerBatchIn,
    AnswerBatchResult,
    ClassCreate,
    ClassMetricsOut,
    StudentMetricsOut,
    StudentUpsert,
    TeacherLogin,
    TeacherRegister,
    TokenResponse,
)

router = APIRouter()


@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/analytics/health")
def analytics_health():
    """Flask-compatible health path used by the iOS client."""
    return {"status": "ok"}


@router.post("/auth/register", response_model=TokenResponse)
def register_teacher(payload: TeacherRegister, db: Session = Depends(get_db)):
    if db.query(Teacher).filter(Teacher.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    teacher = Teacher(
        email=payload.email.lower(),
        display_name=payload.display_name or payload.email.split("@")[0],
        password_hash=hash_password(payload.password),
    )
    db.add(teacher)
    db.commit()
    db.refresh(teacher)
    token = create_access_token(teacher.email, role="teacher", extra={"teacher_id": teacher.id})
    return TokenResponse(access_token=token)


@router.post("/auth/login", response_model=TokenResponse)
def login_teacher(payload: TeacherLogin, db: Session = Depends(get_db)):
    teacher = db.query(Teacher).filter(Teacher.email == payload.email.lower()).first()
    if not teacher or not verify_password(payload.password, teacher.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(teacher.email, role="teacher", extra={"teacher_id": teacher.id})
    return TokenResponse(access_token=token)


@router.post("/auth/device-token", response_model=TokenResponse)
def mint_device_token(
    label: str = "ios-app",
    auth: dict = Depends(require_auth),
    db: Session = Depends(get_db),
):
    """Teachers can mint opaque tokens the iOS app stores for event ingest."""
    if auth.get("role") != "teacher":
        raise HTTPException(status_code=403, detail="Teacher role required")
    raw = secrets.token_urlsafe(32)
    row = APIToken(token_hash=hash_token(raw), label=label, teacher_id=auth.get("teacher_id"))
    db.add(row)
    db.commit()
    return TokenResponse(access_token=raw)


@router.post("/classes", response_model=dict)
def create_class(
    payload: ClassCreate,
    teacher: Teacher = Depends(require_teacher),
    db: Session = Depends(get_db),
):
    code = payload.invite_code or secrets.token_hex(4)
    if db.query(SchoolClass).filter(SchoolClass.invite_code == code).first():
        raise HTTPException(status_code=400, detail="Invite code already exists")
    row = SchoolClass(name=payload.name, teacher_id=teacher.id, invite_code=code)
    db.add(row)
    db.commit()
    db.refresh(row)
    return {"id": row.id, "name": row.name, "invite_code": row.invite_code}


@router.get("/classes", response_model=list)
def list_classes(teacher: Teacher = Depends(require_teacher), db: Session = Depends(get_db)):
    rows = db.query(SchoolClass).filter(SchoolClass.teacher_id == teacher.id).order_by(SchoolClass.id.asc()).all()
    return [{"id": r.id, "name": r.name, "invite_code": r.invite_code} for r in rows]


@router.post("/students/upsert", response_model=dict)
def upsert_student(payload: StudentUpsert, db: Session = Depends(get_db), auth: dict = Depends(require_auth)):
    student = db.query(Student).filter(Student.external_id == payload.external_id).first()
    class_id = None
    if payload.class_invite_code:
        klass = db.query(SchoolClass).filter(SchoolClass.invite_code == payload.class_invite_code).first()
        if not klass:
            raise HTTPException(status_code=404, detail="Class invite code not found")
        class_id = klass.id
    if student is None:
        student = Student(
            external_id=payload.external_id,
            display_name=payload.display_name,
            class_id=class_id,
        )
        db.add(student)
    else:
        if payload.display_name:
            student.display_name = payload.display_name
        if class_id is not None:
            student.class_id = class_id
    db.commit()
    db.refresh(student)
    return {"id": student.id, "external_id": student.external_id, "class_id": student.class_id}


@router.post("/answers/batch", response_model=AnswerBatchResult)
def ingest_answers(payload: AnswerBatchIn, db: Session = Depends(get_db), auth: dict = Depends(require_auth)):
    accepted = duplicates = 0
    batch_class_id = None
    if payload.class_invite_code:
        klass = db.query(SchoolClass).filter(SchoolClass.invite_code == payload.class_invite_code).first()
        if klass:
            batch_class_id = klass.id
    for event in payload.events:
        existing = db.query(AnswerEvent).filter(AnswerEvent.client_event_id == event.client_event_id).first()
        if existing:
            duplicates += 1
            continue
        student = db.query(Student).filter(Student.external_id == event.student_external_id).first()
        if student is None:
            student = Student(
                external_id=event.student_external_id,
                display_name=event.student_name or event.student_external_id,
                class_id=batch_class_id,
            )
            db.add(student)
            db.flush()
        elif batch_class_id is not None:
            student.class_id = batch_class_id
        row = AnswerEvent(
            client_event_id=event.client_event_id,
            student_id=student.id,
            student_external_id=event.student_external_id,
            student_name=event.student_name,
            passage_key=event.passage_key,
            question_key=event.question_key,
            question_type=event.question_type,
            question_preview=event.question_preview,
            student_answer=event.student_answer,
            correct_answer=event.correct_answer,
            is_correct=event.is_correct,
            response_time_seconds=event.response_time_seconds,
            attempt_number=max(1, event.attempt_number),
            pirls_process=event.pirls_process,
            reading_purpose=event.reading_purpose,
            answered_at=event.answered_at or datetime.utcnow(),
        )
        db.add(row)
        accepted += 1
    db.commit()
    return AnswerBatchResult(accepted=accepted, duplicates=duplicates, total=len(payload.events))


@router.get("/analytics/students/{external_id}", response_model=StudentMetricsOut)
async def student_analytics(external_id: str, db: Session = Depends(get_db), auth: dict = Depends(require_auth)):
    student = db.query(Student).filter(Student.external_id == external_id).first()
    events = (
        db.query(AnswerEvent).filter(AnswerEvent.student_external_id == external_id).all()
        if student or True
        else []
    )
    name = student.display_name if student else external_id
    metrics = analyze_student_events(external_id, name, events)
    return await maybe_enrich_with_llm(metrics)


@router.get("/analytics/classes/{class_id}", response_model=ClassMetricsOut)
async def class_analytics(class_id: int, db: Session = Depends(get_db), teacher: Teacher = Depends(require_teacher)):
    klass = db.get(SchoolClass, class_id)
    if klass is None or klass.teacher_id != teacher.id:
        raise HTTPException(status_code=404, detail="Class not found")
    students_payload: List[Tuple[str, str, list[AnswerEvent]]] = []
    for student in klass.students:
        events = db.query(AnswerEvent).filter(AnswerEvent.student_id == student.id).all()
        students_payload.append((student.external_id, student.display_name, events))
    metrics = analyze_class_events(klass.id, klass.name, students_payload)
    return await maybe_enrich_with_llm(metrics)


@router.get("/analytics/students/{external_id}/insights", response_model=StudentMetricsOut)
async def student_insights(external_id: str, db: Session = Depends(get_db), auth: dict = Depends(require_auth)):
    return await student_analytics(external_id, db, auth)


@router.post("/analytics/students/{external_id}/insights", response_model=StudentMetricsOut)
async def student_insights_refresh(external_id: str, db: Session = Depends(get_db), auth: dict = Depends(require_auth)):
    return await student_analytics(external_id, db, auth)


@router.get("/analytics/classes/{class_id}/insights", response_model=ClassMetricsOut)
async def class_insights(class_id: int, db: Session = Depends(get_db), teacher: Teacher = Depends(require_teacher)):
    return await class_analytics(class_id, db, teacher)


@router.post("/analytics/classes/{class_id}/insights", response_model=ClassMetricsOut)
async def class_insights_refresh(class_id: int, db: Session = Depends(get_db), teacher: Teacher = Depends(require_teacher)):
    return await class_analytics(class_id, db, teacher)
