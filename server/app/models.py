from __future__ import annotations

from typing import List, Optional
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class Teacher(Base):
    __tablename__ = "teachers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    display_name: Mapped[str] = mapped_column(String(120), default="")
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    classes: Mapped[List["SchoolClass"]] = relationship(back_populates="teacher")


class SchoolClass(Base):
    __tablename__ = "classes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    teacher_id: Mapped[int] = mapped_column(ForeignKey("teachers.id"))
    invite_code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    teacher: Mapped[Teacher] = relationship(back_populates="classes")
    students: Mapped[List["Student"]] = relationship(back_populates="school_class")


class Student(Base):
    __tablename__ = "students"
    __table_args__ = (UniqueConstraint("external_id", name="uq_student_external"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    external_id: Mapped[str] = mapped_column(String(120), index=True)
    display_name: Mapped[str] = mapped_column(String(120), default="")
    class_id: Mapped[Optional[int]] = mapped_column(ForeignKey("classes.id"), nullable=True)
    device_token: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    school_class: Mapped[SchoolClass | None] = relationship(back_populates="students")
    answers: Mapped[List["AnswerEvent"]] = relationship(back_populates="student")


class AnswerEvent(Base):
    __tablename__ = "answer_events"
    __table_args__ = (UniqueConstraint("client_event_id", name="uq_client_event"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    client_event_id: Mapped[str] = mapped_column(String(64), index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True)
    student_external_id: Mapped[str] = mapped_column(String(120), index=True)
    student_name: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    passage_key: Mapped[str] = mapped_column(String(64), default="")
    question_key: Mapped[str] = mapped_column(String(64), default="")
    question_type: Mapped[str] = mapped_column(String(64), default="")
    question_preview: Mapped[str] = mapped_column(Text, default="")
    student_answer: Mapped[str] = mapped_column(Text, default="")
    correct_answer: Mapped[str] = mapped_column(Text, default="")
    is_correct: Mapped[bool] = mapped_column(Boolean, default=False)
    response_time_seconds: Mapped[float] = mapped_column(Float, default=0.0)
    attempt_number: Mapped[int] = mapped_column(Integer, default=1)
    pirls_process: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    reading_purpose: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    answered_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    received_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    student: Mapped[Student] = relationship(back_populates="answers")


class APIToken(Base):
    __tablename__ = "api_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    label: Mapped[str] = mapped_column(String(120), default="app")
    teacher_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teachers.id"), nullable=True)
    student_id: Mapped[Optional[int]] = mapped_column(ForeignKey("students.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
