import re
from playwright.sync_api import Page, expect
from time import sleep


def test_login(page: Page):
    page.goto("http://localhost:8000/")

    username_field = page.get_by_label(re.compile(r'Username|Nom d\'utilisateur'))
    password_field = page.get_by_label(re.compile(r'Password|Mot de passe'))
    login_button = page.get_by_text(re.compile(r'Login|Se connecter'))
    error_message = page.get_by_text(re.compile(r'The username or the password is incorrec|Le nom d\'utilisateur ou le mot de passe est incorrect'))
    select_pdf = page.get_by_text(re.compile(r'Select PDF|Choisir un PDF'))

    username_field.fill("Graydon")
    password_field.fill("wrong")
    login_button.click()

    sleep(1)
    expect(error_message).not_to_be_visible()

    sleep(4)
    expect(error_message).to_be_visible()

    username_field.fill("Graydon")
    password_field.fill("hashed")
    login_button.click()

    sleep(1)
    expect(select_pdf).not_to_be_visible()

    sleep(4)
    expect(select_pdf).to_be_visible()


def test_forgotten_password(page: Page):
    page.goto("http://localhost:8000/")

    forgotten_password = page.get_by_text(re.compile(r'Forgotten password|Mot de passe oublié'))
    email_field = page.get_by_label(re.compile(r'E-mail address|Adresse e-mail'))
    submit_button = page.get_by_text(re.compile(r'Request new password|Demander un nouveau mot de passe'))
    sent_message = page.get_by_text(re.compile(r'An e-mail has been sent to you|Un e-mail vous a été envoyé'))
    
    forgotten_password.click()
    email_field.fill("example")
    submit_button.click()
    
    sleep(0.5)
    expect(sent_message).not_to_be_visible()

    forgotten_password.click()
    email_field.fill("email@email.email")
    submit_button.click()
    
    sleep(0.5)
    expect(sent_message).to_be_visible()


def test_signup(page: Page):
    page.goto("http://localhost:8000/")

    signup_button = page.get_by_text(re.compile(r'Not registered yet|Pas encore inscrit'))
    signup_button.click()

    username_field = page.get_by_label(re.compile(r'Username|Nom d\'utilisateur'))
    email_field = page.get_by_label(re.compile(r'E-mail address|Adresse e-mail'))
    password_field = page.get_by_text(re.compile(r'Password|Mot de passe'))
    password_confirm_field = page.get_by_text(re.compile(r'Repeat password|Répétez le mot de passe'))
    submit_button = page.get_by_text(re.compile(r'Sign up|S\'inscrire'))
    accept_terms = page.get_by_text(re.compile(r'I read and accept the terms of service|J\'ai lu et j\'accepte les conditions générales d\'utilisation'))
    subscribe_newsletter = page.get_by_text(re.compile(r'I sign up to the newsletter|Je m\'inscris à la newsletter'))
    mail_message = page.get_by_text(re.compile(r'The e-mail address is incorrect|L\'adresse e-mail est erronée'))
    weak_password = page.get_by_text(re.compile(r'The complexity of the password is insufficient|La complexité du mot de passe est insuffisante'))
    short_password = page.get_by_text(re.compile(r'The password must contain at least 6 characters|Le mot de passe doit contenir au moins 6 caractères'))
    nomatch_password = page.get_by_text(re.compile(r'The two passwords don\'t match|Les deux mots de passe ne correspondent pas'))
    must_accept_terms = page.get_by_text(re.compile(r'You must accept the terms of service|Vous devez accepter les conditions générales d\'utilisation'))
    final_message = page.get_by_text(re.compile(r'An account with this username or e-mail address already exists|Un compte avec ce nom d\'utilisateur ou cette adresse e-mail existe déjà|An e-mail has been sent to you|Un e-mail vous a été envoyé'))

    expect(mail_message).to_be_visible()
    expect(short_password).to_be_visible()
    expect(weak_password).not_to_be_visible()
    expect(must_accept_terms).to_be_visible()
    expect(nomatch_password).not_to_be_visible()
    expect(final_message).not_to_be_visible()

    username_field.fill("newuser")
    email_field.fill("bad@email")

    expect(mail_message).to_be_visible()

    email_field.fill("email@email.email")

    expect(mail_message).not_to_be_visible()

    password_field.fill("short")

    expect(short_password).to_be_visible()
    expect(weak_password).not_to_be_visible()
    expect(nomatch_password).to_be_visible()

    password_field.fill("weakbutlong")
    
    expect(short_password).not_to_be_visible()
    expect(weak_password).to_be_visible()
    expect(nomatch_password).to_be_visible()

    password_field.fill("strongpassword:3P")

    expect(short_password).not_to_be_visible()
    expect(weak_password).not_to_be_visible()
    expect(nomatch_password).to_be_visible()

    password_confirm_field.fill("strongpassword:3P")

    expect(short_password).not_to_be_visible()
    expect(weak_password).not_to_be_visible()
    expect(nomatch_password).not_to_be_visible()

    accept_terms.click()

    expect(must_accept_terms).not_to_be_visible()
    expect(accept_terms).to_be_checked()

    subscribe_newsletter.click()

    expect(subscribe_newsletter).to_be_checked()

    submit_button.click()

    expect(final_message).to_be_visible()
