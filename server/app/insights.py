"""Rule-based analytics + optional LLM overlay (DashScope / OpenAI-compatible)."""

from __future__ import annotations

from collections import defaultdict
from typing import Optional, List, Dict, Tuple, Any, Iterable

import httpx

from .config import get_settings
from .models import AnswerEvent
from .schemas import ClassMetricsOut, InsightOut, StudentMetricsOut


def _skill(event: AnswerEvent) -> str:
    return event.pirls_process or event.question_type or "unknown"


def _streaks(events: List[AnswerEvent]) -> Tuple[int, int]:
    best = run = 0
    for e in events:
        if e.is_correct:
            run += 1
            best = max(best, run)
        else:
            run = 0
    current = 0
    for e in reversed(events):
        if e.is_correct:
            current += 1
        else:
            break
    return current, best


def _accuracy_by(events: List[AnswerEvent], key_fn) -> Dict[str, float]:
    buckets: Dict[str, List[bool]] = defaultdict(list)
    for e in events:
        buckets[key_fn(e)].append(e.is_correct)
    out: Dict[str, float] = {}
    for k, vals in buckets.items():
        if len(vals) >= 2:
            out[k] = sum(1 for v in vals if v) / len(vals)
    return out


def _weakest(acc: Dict[str, float], limit: int = 3) -> List[str]:
    return [k for k, _ in sorted(acc.items(), key=lambda kv: (kv[1], kv[0]))[:limit]]


def analyze_student_events(
    student_external_id: str,
    student_name: str,
    events: Iterable[AnswerEvent],
) -> StudentMetricsOut:
    ordered = sorted(list(events), key=lambda e: e.answered_at)
    total = len(ordered)
    accuracy = (sum(1 for e in ordered if e.is_correct) / total) if total else 0.0
    avg_time = (sum(e.response_time_seconds for e in ordered) / total) if total else 0.0
    current, best = _streaks(ordered)
    by_skill = _accuracy_by(ordered, _skill)
    by_type = _accuracy_by(ordered, lambda e: e.question_type or "unknown")
    weak_skills = _weakest(by_skill)
    weak_types = _weakest(by_type)
    insights: List[InsightOut] = []
    if total == 0:
        insights.append(InsightOut(kind="info", title="No data", detail="No answers yet.", action=None))
    else:
        if weak_skills:
            insights.append(
                InsightOut(
                    kind="weakness",
                    title="Skills to strengthen",
                    detail="Lower accuracy in: " + ", ".join(weak_skills),
                    action="Assign short practice passages targeting these PIRLS processes.",
                )
            )
        strong = [k for k, v in by_skill.items() if v >= 0.75]
        if strong:
            insights.append(
                InsightOut(
                    kind="strength",
                    title="Strengths",
                    detail="Solid performance in: " + ", ".join(strong[:2]),
                    action=None,
                )
            )
        if total >= 6 and accuracy < 0.45:
            insights.append(
                InsightOut(
                    kind="at_risk",
                    title="At-risk flag",
                    detail=f"Accuracy {accuracy:.0%} across {total} answers.",
                    action="Schedule a short 1:1 review and reduce difficulty one step.",
                )
            )
        insights.append(
            InsightOut(
                kind="info",
                title="Pace",
                detail=f"Average response {avg_time:.1f}s; streak {current} (best {best}).",
                action=None,
            )
        )
    return StudentMetricsOut(
        student_external_id=student_external_id,
        student_name=student_name or student_external_id,
        total_answers=total,
        accuracy=accuracy,
        average_response_time=avg_time,
        current_streak=current,
        best_streak=best,
        accuracy_by_skill=by_skill,
        weakest_skills=weak_skills,
        weakest_question_types=weak_types,
        insights=insights,
        source="rule_based",
    )


def analyze_class_events(
    class_id: int,
    class_name: str,
    students: List[Tuple[str, str, list[AnswerEvent]]],
) -> ClassMetricsOut:
    per_student = [
        analyze_student_events(ext, name, events) for ext, name, events in students
    ]
    all_events = [e for _, _, evs in students for e in evs]
    total = len(all_events)
    class_acc = (sum(1 for e in all_events if e.is_correct) / total) if total else 0.0
    avg_time = (sum(e.response_time_seconds for e in all_events) / total) if total else 0.0
    by_skill = _accuracy_by(all_events, _skill)
    weak = _weakest(by_skill)
    at_risk = [s.student_name for s in per_student if s.total_answers >= 6 and s.accuracy < 0.45]
    insights: List[InsightOut] = [
        InsightOut(
            kind="info",
            title="Class overview",
            detail=f"{len(per_student)} students, {total} answers, accuracy {class_acc:.0%}.",
            action=None,
        )
    ]
    if weak:
        insights.append(
            InsightOut(
                kind="weakness",
                title="Class weak skills",
                detail=", ".join(weak),
                action="Plan a shared mini-lesson on the weakest process.",
            )
        )
    if at_risk:
        insights.append(
            InsightOut(
                kind="at_risk",
                title="Students to watch",
                detail=", ".join(at_risk),
                action="Follow up individually this week.",
            )
        )
    return ClassMetricsOut(
        class_id=class_id,
        class_name=class_name,
        student_count=len(per_student),
        total_answers=total,
        class_accuracy=class_acc,
        average_response_time=avg_time,
        accuracy_by_skill=by_skill,
        weakest_skills=weak,
        at_risk_students=at_risk,
        insights=insights,
        per_student=per_student,
        source="rule_based",
    )


async def maybe_enrich_with_llm(metrics: StudentMetricsOut | ClassMetricsOut) -> StudentMetricsOut | ClassMetricsOut:
    """If LLM credentials exist, append a short narrative insight; else return unchanged."""
    settings = get_settings()
    if not (settings.llm_enabled and settings.llm_api_key and settings.llm_api_base):
        return metrics

    summary = metrics.model_dump()
    prompt = (
        "You are an education coach for Chinese primary reading (PIRLS). "
        "Given this JSON metrics object, write 2 short plain-language insights "
        "and 1 concrete next-step recommendation in Traditional Chinese. "
        "No markdown, no bullet symbols.\n\n"
        f"{summary}"
    )
    url = settings.llm_api_base.rstrip("/") + "/chat/completions"
    headers = {"Authorization": f"Bearer {settings.llm_api_key}", "Content-Type": "application/json"}
    body = {
        "model": settings.llm_model,
        "messages": [
            {"role": "system", "content": "Return concise teacher-facing Chinese advice."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
    }
    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            resp = await client.post(url, headers=headers, json=body)
            resp.raise_for_status()
            data = resp.json()
            text = data["choices"][0]["message"]["content"].strip()
        metrics.insights.append(
            InsightOut(kind="recommendation", title="AI analysis", detail=text, action=None)
        )
        metrics.source = "llm+rule_based"
    except Exception as exc:  # noqa: BLE001 — fall back silently
        metrics.insights.append(
            InsightOut(
                kind="info",
                title="AI unavailable",
                detail=f"Using rule-based insights only ({exc.__class__.__name__}).",
                action=None,
            )
        )
    return metrics
