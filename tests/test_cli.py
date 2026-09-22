from app.cli import greet, main


def test_greet():
    assert greet("Claude") == "Hello, Claude!"


def test_main(capsys):
    assert main(["Yuki"]) == 0
    assert capsys.readouterr().out == "Hello, Yuki!\n"
