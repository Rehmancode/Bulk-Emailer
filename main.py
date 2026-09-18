import sys


def main():
    # Must run before importing PyQt6/pandas/etc -- those might be the
    # very packages that are missing on a fresh machine. See bootstrap.py
    # for why this is skipped entirely inside the compiled .exe.
    from app.bootstrap import ensure_dependencies
    if not ensure_dependencies():
        sys.exit(1)

    from PyQt6.QtWidgets import QApplication
    from app.main_window import MainWindow

    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
