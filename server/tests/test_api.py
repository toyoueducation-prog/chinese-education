from datetime import datetime

def _auth_header(client):
    r = client.post("/api/auth/register", json={
        "email": "teacher@example.com",
        "password": "secret12",
        "display_name": "Ms Lee",
    })
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}

def test_health(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
    r2 = client.get("/api/analytics/health")
    assert r2.status_code == 200
    assert r2.json()["status"] == "ok"

def test_register_login_and_class(client):
    headers = _auth_header(client)
    r = client.post("/api/classes", json={"name": "P3A"}, headers=headers)
    assert r.status_code == 200
    assert "invite_code" in r.json()
    listed = client.get("/api/classes", headers=headers)
    assert listed.status_code == 200
    assert any(c["name"] == "P3A" for c in listed.json())

def test_answer_batch_and_student_analytics(client):
    headers = _auth_header(client)
    klass = client.post("/api/classes", json={"name": "P4B", "invite_code": "p4bdemo"}, headers=headers).json()
    client.post("/api/students/upsert", json={
        "external_id": "stu-1",
        "display_name": "Amy",
        "class_invite_code": klass["invite_code"],
    }, headers=headers)
    events = []
    for i in range(8):
        events.append({
            "client_event_id": f"e{i}",
            "student_external_id": "stu-1",
            "student_name": "Amy",
            "passage_key": "passage1",
            "question_key": f"q{i}",
            "question_type": "mc",
            "question_preview": "preview",
            "student_answer": "A",
            "correct_answer": "A",
            "is_correct": i % 2 == 0,
            "response_time_seconds": 10 + i,
            "attempt_number": 1,
            "pirls_process": "retrieving" if i < 4 else "inferring",
            "answered_at": datetime.utcnow().isoformat(),
        })
    batch = client.post(
        "/api/answers/batch",
        json={"events": events, "class_invite_code": klass["invite_code"]},
        headers=headers,
    )
    assert batch.status_code == 200
    assert batch.json()["accepted"] == 8
    again = client.post("/api/answers/batch", json={"events": events[:2]}, headers=headers)
    assert again.json()["duplicates"] == 2
    metrics = client.get("/api/analytics/students/stu-1", headers=headers)
    assert metrics.status_code == 200
    body = metrics.json()
    assert body["total_answers"] == 8
    assert body["insights"]
    insights = client.get("/api/analytics/students/stu-1/insights", headers=headers)
    assert insights.status_code == 200
    assert insights.json()["insights"]
    class_metrics = client.get(f"/api/analytics/classes/{klass['id']}", headers=headers)
    assert class_metrics.status_code == 200
    assert class_metrics.json()["student_count"] == 1

def test_rule_based_at_risk(client):
    headers = _auth_header(client)
    events = [{
        "client_event_id": f"risk{i}",
        "student_external_id": "risk-1",
        "student_name": "Bob",
        "passage_key": "passage2",
        "question_key": f"rq{i}",
        "question_type": "mc",
        "is_correct": False,
        "response_time_seconds": 30,
        "attempt_number": 1,
        "pirls_process": "evaluating",
        "answered_at": datetime.utcnow().isoformat(),
    } for i in range(8)]
    client.post("/api/answers/batch", json={"events": events}, headers=headers)
    body = client.get("/api/analytics/students/risk-1", headers=headers).json()
    assert body["accuracy"] < 0.45
    assert any(i["kind"] == "at_risk" for i in body["insights"])
