import re
from playwright.sync_api import Page, expect
from time import sleep


def test_select_pdf(page: Page):
    page.goto("http://localhost:8000/")

    username_field = page.get_by_label(re.compile(r"Username|Nom d'utilisateur"))
    password_field = page.get_by_label(re.compile(r"Password|Mot de passe"))
    login_button = page.get_by_text(re.compile(r"Login|Se connecter"))
    select_pdf = page.get_by_text(re.compile(r"Select PDF|Choisir un PDF"))
    file_input = page.locator("input[type=file]")
    start_recording = page.get_by_text(re.compile(r"Start recording|Démarrer l'enregistrement"))
    organize_slides = page.get_by_text(re.compile(r"Organize slides|Organiser les planches"))
    cancel = page.get_by_text(re.compile(r"Cancel|Annuler"))
    logo = page.locator("img")
    project_name = page.get_by_label(re.compile(r"Project name|Nom du projet"))
    capsule_name = page.get_by_label(re.compile(r"Capsule name|Nom de la capsule"))
    cancel_project = page.get_by_text("cancel_project")
    cancel_capsule = page.get_by_text("cancel_capsule")
    home_project = page.get_by_text("home_project")
    home_capsule = page.get_by_text("home_capsule")
    new_project = page.get_by_text(re.compile(r"New project|Nouveau projet"))
    demopolymny = page.get_by_text("DemoPolymny")

    username_field.fill("Graydon")
    password_field.fill("hashed")
    login_button.click()

    select_pdf.click()
    file_input.set_input_files("../../DemoPolymny.pdf")
    project_name.fill("cancel_project")
    capsule_name.fill("cancel_capsule")
    cancel.click()

    expect(cancel_capsule).not_to_be_visible()
    expect(cancel_project).not_to_be_visible()
    expect(new_project).not_to_be_visible()
    expect(demopolymny).not_to_be_visible()

    select_pdf.click()
    file_input.set_input_files("../../DemoPolymny.pdf")
    project_name.fill("home_project")
    capsule_name.fill("home_capsule")
    logo.click()

    expect(home_capsule).not_to_be_visible()
    expect(home_project).not_to_be_visible()
    expect(new_project).not_to_be_visible()
    expect(demopolymny).not_to_be_visible()

    sleep(5)

    expect(home_capsule).not_to_be_visible()
    expect(home_project).not_to_be_visible()
    expect(new_project).not_to_be_visible()
    expect(demopolymny).not_to_be_visible()
