from __future__ import annotations
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime

from pydantic import BaseModel, Field


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TeacherRegister(BaseModel):
    email: str
    password: str = Field(min_length=6)
    display_name: str = ""


class TeacherLogin(BaseModel):
    email: str
    password: str


class ClassCreate(BaseModel):
    name: str
    invite_code: Optional[str] = None


class StudentUpsert(BaseModel):
    external_id: str
    display_name: str = ""
    class_invite_code: Optional[str] = None


class AnswerEventIn(BaseModel):
    client_event_id: str
    student_external_id: str
    student_name: Optional[str] = None
    passage_key: str = ""
    question_key: str = ""
    question_type: str = ""
    question_preview: str = ""
    student_answer: str = ""
    correct_answer: str = ""
    is_correct: bool
    response_time_seconds: float = 0.0
    attempt_number: int = 1
    pirls_process: Optional[str] = None
    reading_purpose: Optional[str] = None
    answered_at: Optional[datetime] = None


class AnswerBatchIn(BaseModel):
    events: List[AnswerEventIn]


class AnswerBatchResult(BaseModel):
    accepted: int
    duplicates: int
    total: int


class InsightOut(BaseModel):
    kind: str
    title: str
    detail: str
    action: Optional[str] = None


class StudentMetricsOut(BaseModel):
    student_external_id: str
    student_name: str
    total_answers: int
    accuracy: float
    average_response_time: float
    current_streak: int
    best_streak: int
    accuracy_by_skill: Dict[str, float]
    weakest_skills: List[str]
    weakest_question_types: List[str]
    insights: List[InsightOut]
    source: str = "rule_based"


class ClassMetricsOut(BaseModel):
    class_id: int
    class_name: str
    student_count: int
    total_answers: int
    class_accuracy: float
    average_response_time: float
    accuracy_by_skill: Dict[str, float]
    weakest_skills: List[str]
    at_risk_students: List[str]
    insights: List[InsightOut]
    per_student: List[StudentMetricsOut]
    source: str = "rule_based"
