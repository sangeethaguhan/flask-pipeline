from hello import app

def test_root_returns_hello_world():
    c = app.test_client()
    r = c.get("/")
    assert r.status_code == 200
    assert b"Hello World!" in r.data
