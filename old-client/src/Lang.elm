module Lang exposing (..)

import Capsule
import Json.Decode as Decode exposing (Decoder)
import Utils exposing (tern)


type Lang
    = FrFr
    | EnUs


decode : Decoder (Maybe Lang)
decode =
    Decode.string |> Decode.andThen (\str -> Decode.succeed (fromString str))


default : Lang
default =
    FrFr


toString : Lang -> String
toString lang =
    case lang of
        FrFr ->
            "fr-FR"

        EnUs ->
            "en-US"


fromString : String -> Maybe Lang
fromString string =
    if String.startsWith "fr-" string then
        Just FrFr

    else if String.startsWith "en-" string then
        Just EnUs

    else
        Nothing


other : Lang -> Lang
other lang =
    case lang of
        FrFr ->
            EnUs

        _ ->
            FrFr


view : Lang -> String
view lang =
    case lang of
        FrFr ->
            "Français"

        _ ->
            "English"


logout : Lang -> String
logout lang =
    case lang of
        FrFr ->
            "Se déconnecter"

        _ ->
            "Log out"


projectName : Lang -> String
projectName lang =
    case lang of
        FrFr ->
            "Nom du projet"

        _ ->
            "Project name"


progress : Lang -> String
progress lang =
    case lang of
        FrFr ->
            "Progression"

        _ ->
            "Progress"


actions : Lang -> String
actions lang =
    case lang of
        FrFr ->
            "Actions"

        _ ->
            "Actions"


capsule : Lang -> Int -> String
capsule lang count =
    case lang of
        FrFr ->
            tern (count <= 1) "capsule" "capsules"

        _ ->
            tern (count <= 1) "capsule" "capsules"


produced : Lang -> Int -> String
produced lang count =
    case lang of
        FrFr ->
            tern (count <= 1) "produite" "produites"

        _ ->
            "produced"


published : Lang -> Int -> String
published lang count =
    case lang of
        FrFr ->
            tern (count <= 1) "publiée" "publiées"

        _ ->
            "published"


acquisition : Lang -> String
acquisition lang =
    case lang of
        FrFr ->
            "acquisition"

        _ ->
            "acquisition"


production : Lang -> String
production lang =
    case lang of
        FrFr ->
            "production"

        _ ->
            "production"


publication : Lang -> String
publication lang =
    case lang of
        FrFr ->
            "publication"

        _ ->
            "publication"


newCapsule : Lang -> String
newCapsule lang =
    case lang of
        FrFr ->
            "Nouvelle capsule"

        _ ->
            "New capsule"


renameCapsule : Lang -> String
renameCapsule lang =
    case lang of
        FrFr ->
            "Renommer la capsule"

        _ ->
            "Rename capsule"


deleteCapsule : Lang -> String
deleteCapsule lang =
    case lang of
        FrFr ->
            "Supprimer la capsule"

        _ ->
            "Delete capsule"


nbCapsules : Lang -> String
nbCapsules lang =
    case lang of
        FrFr ->
            "Nb capsules"

        _ ->
            "Capsules count"


capsules : Lang -> String
capsules lang =
    case lang of
        FrFr ->
            "Capsules"

        _ ->
            "Capsules"


renameProject : Lang -> String
renameProject lang =
    case lang of
        FrFr ->
            "Renommer le projet"

        _ ->
            "Supprimer le projet"


deleteProject : Lang -> String
deleteProject lang =
    case lang of
        FrFr ->
            "Supprimer le projet"

        _ ->
            "Delete project"


role : Lang -> String
role lang =
    case lang of
        FrFr ->
            "Rôle"

        _ ->
            "Role"


roleView : Lang -> Capsule.Role -> String
roleView lang r =
    case ( lang, r ) of
        ( FrFr, Capsule.Owner ) ->
            "Propriétaire"

        ( FrFr, Capsule.Write ) ->
            "Écriture"

        ( FrFr, Capsule.Read ) ->
            "Lecture"

        ( _, Capsule.Owner ) ->
            "Owner"

        ( _, Capsule.Write ) ->
            "Write"

        ( _, Capsule.Read ) ->
            "Read"


warning : Lang -> String
warning lang =
    case lang of
        FrFr ->
            "Attention"

        _ ->
            "Warning"


deleteCapsuleConfirm : Lang -> String
deleteCapsuleConfirm lang =
    case lang of
        FrFr ->
            "Voulez-vous vraiment supprimer la capsule ?"

        _ ->
            "Do you really want to delete the capsule?"


deleteProjectConfirm : Lang -> String
deleteProjectConfirm lang =
    case lang of
        FrFr ->
            "Voulez-vous vraiment supprimer le projet ?"

        _ ->
            "Do you really want to delete the project?"


confirm : Lang -> String
confirm lang =
    case lang of
        FrFr ->
            "Valider"

        _ ->
            "Confirm"


cancel : Lang -> String
cancel lang =
    case lang of
        FrFr ->
            "Annuler"

        _ ->
            "Cancel"


capsuleId : Lang -> String
capsuleId lang =
    case lang of
        FrFr ->
            "Hash Id"

        _ ->
            "Hash Id"


capsuleName : Lang -> String
capsuleName lang =
    case lang of
        FrFr ->
            "Nom de la capsule"

        _ ->
            "Capsule name"


slidesGroup : Lang -> String
slidesGroup lang =
    case lang of
        FrFr ->
            "Regroupement des planches"

        _ ->
            "Slides grouping"


slidesGroupSubtext : Lang -> String
slidesGroupSubtext lang =
    case lang of
        FrFr ->
            "Les slides séparés par des pointillets seront filmés en une fois"

        _ ->
            "Slides separated by dashed lines will be recorded at once"


startRecording : Lang -> String
startRecording lang =
    case lang of
        FrFr ->
            "Commencer l'enregistrement"

        _ ->
            "Start recording"


prepareSlides : Lang -> String
prepareSlides lang =
    case lang of
        FrFr ->
            "Organiser les planches"

        _ ->
            "Organize slides"


prepare : Lang -> String
prepare lang =
    case lang of
        FrFr ->
            "Préparer"

        _ ->
            "Prepare"


record : Lang -> String
record lang =
    case lang of
        FrFr ->
            "Filmer"

        _ ->
            "Record"


produce : Lang -> String
produce lang =
    case lang of
        FrFr ->
            "Produire"

        _ ->
            "Produce"


userId : Lang -> String
userId lang =
    case lang of
        FrFr ->
            "ID utilisateur"

        _ ->
            "User Id"


username : Lang -> String
username lang =
    case lang of
        FrFr ->
            "Nom d'utilisateur"

        _ ->
            "Username"


password : Lang -> String
password lang =
    case lang of
        FrFr ->
            "Mot de passe"

        _ ->
            "Password"


emailAddress : Lang -> String
emailAddress lang =
    case lang of
        FrFr ->
            "Adresse e-mail"

        _ ->
            "Email address"


currentEmail : Lang -> String
currentEmail lang =
    case lang of
        FrFr ->
            "Adresse e-mail actuelle"

        _ ->
            "Current email address"


activatedUser : Lang -> String
activatedUser lang =
    case lang of
        FrFr ->
            "Utilsateur actif"

        _ ->
            "Active user"


newsletter : Lang -> String
newsletter lang =
    case lang of
        FrFr ->
            "Inscrit à la newsletter"

        _ ->
            "Newslettter subscitption"


newEmail : Lang -> String
newEmail lang =
    case lang of
        FrFr ->
            "Nouvelle adresse e-mail"

        _ ->
            "New email address"


repeatPassword : Lang -> String
repeatPassword lang =
    case lang of
        FrFr ->
            "Retapez votre mot de passe"

        _ ->
            "Repeat your password"


conditions : Lang -> String
conditions lang =
    case lang of
        FrFr ->
            "Conditions d'utilisation"

        _ ->
            "Conditions of use"


acceptConditions : Lang -> String
acceptConditions lang =
    case lang of
        FrFr ->
            "J'ai lu les conditions d'utilisation et les accepte"

        _ ->
            "I read the conditions of use and I accept it"


registerNewsletter : Lang -> String
registerNewsletter lang =
    case lang of
        FrFr ->
            "Je m'inscris à la newsletter de Polymny Studio"

        _ ->
            "I sign up for Polymny Studio newsletter"


userPlan : Lang -> String
userPlan lang =
    case lang of
        FrFr ->
            "Type d'offre"

        _ ->
            "Plan"


notRegisteredYet : Lang -> String
notRegisteredYet lang =
    case lang of
        FrFr ->
            "Pas encore inscrit ?"

        _ ->
            "Not registered yet?"


forgotYourPassword : Lang -> String
forgotYourPassword lang =
    case lang of
        FrFr ->
            "Mot de passe oublié ?"

        _ ->
            "Forgot your password?"


login : Lang -> String
login lang =
    case lang of
        FrFr ->
            "Se connecter"

        _ ->
            "Login"


resetPassword : Lang -> String
resetPassword lang =
    case lang of
        FrFr ->
            "Réinitialiser mon mot de passe"

        _ ->
            "Reset my password"


signUp : Lang -> String
signUp lang =
    case lang of
        FrFr ->
            "S'inscrire"

        _ ->
            "Sign up"


loginFailed : Lang -> String
loginFailed lang =
    case lang of
        FrFr ->
            "Connexion échouée"

        _ ->
            "Connection failed"


askNewPassword : Lang -> String
askNewPassword lang =
    case lang of
        FrFr ->
            "Demander un nouveau mot de passe"

        _ ->
            "Request a new password"


noSuchEmail : Lang -> String
noSuchEmail lang =
    case lang of
        FrFr ->
            "Cette adresse e-mail n'est associée à aucun compte"

        _ ->
            "This email address does not belong to any account"


mailSent : Lang -> String
mailSent lang =
    case lang of
        FrFr ->
            "Un e-mail vous a été envoyé"

        _ ->
            "An email has been sent to you"


changePassword : Lang -> String
changePassword lang =
    case lang of
        FrFr ->
            "Changer le mot de passe"

        _ ->
            "Change password"


passwordChanged : Lang -> String
passwordChanged lang =
    case lang of
        FrFr ->
            "Le mot de passe a été changé !"

        _ ->
            "Password has been changed!"


newPassword : Lang -> String
newPassword lang =
    case lang of
        FrFr ->
            "Nouveau mot de passe"

        _ ->
            "New password"


invalidEmail : Lang -> String
invalidEmail lang =
    case lang of
        FrFr ->
            "l'adresse e-email est incorrecte"

        _ ->
            "email address is invalid"


incorrectPassword : Lang -> String
incorrectPassword lang =
    case lang of
        FrFr ->
            "Le mot de passe est incorrect"

        _ ->
            "the password is incorrect"


usernameMustBeAtLeast3 : Lang -> String
usernameMustBeAtLeast3 lang =
    case lang of
        FrFr ->
            "le nom d'utilisateur doit contenir au moins 3 caractères"

        _ ->
            "username must have at least 3 characters"


passwordsDontMatch : Lang -> String
passwordsDontMatch lang =
    case lang of
        FrFr ->
            "les deux mot de passes ne correspondent pas"

        _ ->
            "the two passwords don't match"


errorsInSignUpForm : Lang -> String
errorsInSignUpForm lang =
    case lang of
        FrFr ->
            "Il y a des erreurs dans le formulaire :"

        _ ->
            "Form contains errors:"


mustAcceptConditions : Lang -> String
mustAcceptConditions lang =
    case lang of
        FrFr ->
            "vous devez accepter les conditions d'utilisation"

        _ ->
            "you must accept the conditions of use"


accountActivated : Lang -> String
accountActivated lang =
    case lang of
        FrFr ->
            "Votre adresse email a été correctement activé !"

        _ ->
            "Your email address has been successfully activated!"


editUser : Lang -> String
editUser lang =
    case lang of
        FrFr ->
            "Editer l'utilisateur"

        _ ->
            "Edit user"


deleteUser : Lang -> String
deleteUser lang =
    case lang of
        FrFr ->
            "Supprimer l'utilisateur"

        _ ->
            "Delete user"


goToPolymny : Lang -> String
goToPolymny lang =
    case lang of
        FrFr ->
            "Aller sur Polymny"

        _ ->
            "Go to Polymny"


zoomIn : Lang -> String
zoomIn lang =
    case lang of
        FrFr ->
            "Zoomer"

        _ ->
            "Zoom in"


zoomOut : Lang -> String
zoomOut lang =
    case lang of
        FrFr ->
            "Dézoomer"

        _ ->
            "Zoom out"


promptEdition : Lang -> String
promptEdition lang =
    case lang of
        FrFr ->
            "Édition du prompteur"

        _ ->
            "Prompt edition"


goToNextSlide : Lang -> String
goToNextSlide lang =
    case lang of
        FrFr ->
            "Aller au slide suivant"

        _ ->
            "Go to next slide"


goToPreviousSlide : Lang -> String
goToPreviousSlide lang =
    case lang of
        FrFr ->
            "Aller au slide précédent"

        _ ->
            "Go to previous slide"


editPrompt : Lang -> String
editPrompt lang =
    case lang of
        FrFr ->
            "Éditer le texte du prompteur"

        _ ->
            "Edit prompt text"


deleteSlide : Lang -> String
deleteSlide lang =
    case lang of
        FrFr ->
            "Supprimer le slide"

        _ ->
            "Delete slide"


deleteSlideConfirm : Lang -> String
deleteSlideConfirm lang =
    case lang of
        FrFr ->
            "Voulez-vous vraiment supprimer ce slide ?"

        _ ->
            "Do you really want to delete this slide?"


webcam : Lang -> String
webcam lang =
    case lang of
        FrFr ->
            "Webcam"

        _ ->
            "Webcam"


resolution : Lang -> String
resolution lang =
    case lang of
        FrFr ->
            "Résolution"

        _ ->
            "Resolution"


disabled : Lang -> String
disabled lang =
    case lang of
        FrFr ->
            "Désactivé"

        _ ->
            "Disabled"


microphone : Lang -> String
microphone lang =
    case lang of
        FrFr ->
            "Micro"

        _ ->
            "Microphone"


slide : Lang -> String
slide lang =
    case lang of
        FrFr ->
            "Planche"

        _ ->
            "Slide"


line : Lang -> String
line lang =
    case lang of
        FrFr ->
            "Ligne"

        _ ->
            "Line"


recordingStopped : Lang -> String
recordingStopped lang =
    case lang of
        FrFr ->
            "Enregistrement arrété"

        _ ->
            "Recording stopped"


invertSlideAndPrompt : Lang -> String
invertSlideAndPrompt lang =
    case lang of
        FrFr ->
            "Inverser le slide et le prompteur"

        _ ->
            "Invert slide and prompt"


version : Lang -> String
version lang =
    case lang of
        FrFr ->
            "Version"

        _ ->
            "Version"


commit : Lang -> String
commit lang =
    case lang of
        FrFr ->
            "Commit"

        _ ->
            "Commit"


source : Lang -> String
source lang =
    case lang of
        FrFr ->
            "Source"

        _ ->
            "Source"


settings : Lang -> String
settings lang =
    case lang of
        FrFr ->
            "Paramètres"

        _ ->
            "Settings"


records : Lang -> String
records lang =
    case lang of
        FrFr ->
            "Enregistrements"

        _ ->
            "Records"


playRecord : Lang -> String
playRecord lang =
    case lang of
        FrFr ->
            "Jouer l'enregistrement"

        _ ->
            "Play record"


stopRecord : Lang -> String
stopRecord lang =
    case lang of
        FrFr ->
            "Arrêter la relecture l'enregistrement"

        _ ->
            "Stop record replay"


dndWillBreak : Lang -> String
dndWillBreak lang =
    case lang of
        FrFr ->
            "Ce déplacement va détruire certains de vos enregistrements. Êtes-vous sûr de vouloir poursuivre ?"

        _ ->
            "This change will destroy some of your records. Are you sure you want to proceed?"


uploadRecord : Lang -> String
uploadRecord lang =
    case lang of
        FrFr ->
            "Valider cet enregistrement"

        _ ->
            "Validate this record"


recordGos : Lang -> String
recordGos lang =
    case lang of
        FrFr ->
            "Enregistrer ce groupe de slides"

        _ ->
            "Record this group of slides"


watchRecord : Lang -> String
watchRecord lang =
    case lang of
        FrFr ->
            "Regarder cet enregistrement"

        _ ->
            "Watch this record"


welcomeOnPolymny : Lang -> String
welcomeOnPolymny lang =
    case lang of
        FrFr ->
            "Bienvenue sur Polymny !"

        _ ->
            "Welcome on Polymny!"


noProjectsYet : Lang -> String
noProjectsYet lang =
    case lang of
        FrFr ->
            "On dirait que vous n'avez encore aucun projet..."

        _ ->
            "It looks like you have no project yet..."


startRecordSentence : Lang -> String
startRecordSentence lang =
    case lang of
        FrFr ->
            "Pour commencer un enregistrement, il faut choisir une présentation au format PDF sur votre machine."

        _ ->
            "To start recording, you need to choose a PDF slides from your computer."


nextSentence : Lang -> String
nextSentence lang =
    case lang of
        FrFr ->
            "Par exemple, un export PDF de Microsoft PowerPoint ou LibreOffice Impress en paysage au format HD. Une fois la présentation téléchargée, l'enregistrement vidéo des planches pourra débuter."

        _ ->
            "For example, a PDF export version of Microsoft PowerPoint or LibreOffice Impress in HD format. Once the slides have been uploaded, the recording can start."


selectPdf : Lang -> String
selectPdf lang =
    case lang of
        FrFr ->
            "Choisir un fichier PDF"

        _ ->
            "Select a PDF file"


replaceSlideOrAddExternalResource : Lang -> String
replaceSlideOrAddExternalResource lang =
    case lang of
        FrFr ->
            "Remplacer le slide / ajouter une ressource externe"

        _ ->
            "Replace slide / add external resource"


replaceSlide : Lang -> String
replaceSlide lang =
    case lang of
        FrFr ->
            "Remplacer un slide"

        _ ->
            "Replace slide"


whichPage : Lang -> String
whichPage lang =
    case lang of
        FrFr ->
            "Quelle page du PDF voulez-vous utiliser ?"

        _ ->
            "Which PDF page do you want to use?"


insertNumber : Lang -> String
insertNumber lang =
    case lang of
        FrFr ->
            "Entrez un numéro de slide plus grand que 0"

        _ ->
            "Enter a slide number greater than 0"


loading : Lang -> String
loading lang =
    case lang of
        FrFr ->
            "Chargement"

        _ ->
            "Loading"


uploading : Lang -> String
uploading lang =
    case lang of
        FrFr ->
            "Envoi en cours, veuillez patienter..."

        _ ->
            "Upload in progress, please wait..."


transcoding : Lang -> String
transcoding lang =
    case lang of
        FrFr ->
            "Transcodage du fichier vidéo, veuillez patienter..."

        _ ->
            "Video transcoding, please wait..."


deleteExtraResource : Lang -> String
deleteExtraResource lang =
    case lang of
        FrFr ->
            "Supprimer la ressource externe"

        _ ->
            "Delete extra resource"


currentPassword : Lang -> String
currentPassword lang =
    case lang of
        FrFr ->
            "Mot de passe actuel"

        _ ->
            "Current password"


useVideo : Lang -> String
useVideo lang =
    case lang of
        FrFr ->
            "Incruster la vidéo"

        _ ->
            "Use webcam video"


webcamSize : Lang -> String
webcamSize lang =
    case lang of
        FrFr ->
            "Taille de la webcam"

        _ ->
            "Webcam size"


small : Lang -> String
small lang =
    case lang of
        FrFr ->
            "Petite"

        _ ->
            "Small"


medium : Lang -> String
medium lang =
    case lang of
        FrFr ->
            "Moyenne"

        _ ->
            "Medium"


large : Lang -> String
large lang =
    case lang of
        FrFr ->
            "Grosse"

        _ ->
            "Large"


webcamAnchor : Lang -> String
webcamAnchor lang =
    case lang of
        FrFr ->
            "Position de la webcam"

        _ ->
            "Webcam position"


topLeft : Lang -> String
topLeft lang =
    case lang of
        FrFr ->
            "En haut à gauche"

        _ ->
            "Top-left corner"


topRight : Lang -> String
topRight lang =
    case lang of
        FrFr ->
            "En haut à droite"

        _ ->
            "Top-right corner"


bottomLeft : Lang -> String
bottomLeft lang =
    case lang of
        FrFr ->
            "En bas à gauche"

        _ ->
            "Bottom-left corner"


bottomRight : Lang -> String
bottomRight lang =
    case lang of
        FrFr ->
            "En bas à droite"

        _ ->
            "Bottom-right corner"


lastModified : Lang -> String
lastModified lang =
    case lang of
        FrFr ->
            "Dernière modification"

        _ ->
            "Last modified"


diskUsage : Lang -> String
diskUsage lang =
    case lang of
        FrFr ->
            "Taille (MiB)"

        _ ->
            "Size (MiB)"


driveSpace : Lang -> String
driveSpace lang =
    case lang of
        FrFr ->
            "Espace de stockage"

        _ ->
            "Drive space"


spaceUsed : Lang -> String -> String -> String
spaceUsed lang used max =
    case lang of
        FrFr ->
            used ++ " Go utilsés sur " ++ max ++ " Go"

        _ ->
            used ++ " GB used on " ++ max ++ " GB"


produceVideo : Lang -> String
produceVideo lang =
    case lang of
        FrFr ->
            "Produire la vidéo"

        _ ->
            "Produce video"


produceGosVideo : Lang -> String -> String
produceGosVideo lang gos =
    case lang of
        FrFr ->
            "Produire le grain " ++ gos

        _ ->
            "Produce grain " ++ gos


publish : Lang -> String
publish lang =
    case lang of
        FrFr ->
            "Publier"

        _ ->
            "Publish"


currentProducedVideo : Lang -> String
currentProducedVideo lang =
    case lang of
        FrFr ->
            "Vidéo produite actuelle"

        _ ->
            "Current produced video"


videoNotProduced : Lang -> String
videoNotProduced lang =
    case lang of
        FrFr ->
            "La vidéo n'a pas encore été produite"

        _ ->
            "Video has not been produced yet"


cantPublishBecauseNotProduced : Lang -> String
cantPublishBecauseNotProduced lang =
    case lang of
        FrFr ->
            "Pour publier la vidéo, vous devez d'abord la produire"

        _ ->
            "To publish the video, you must first produce it"


publishVideo : Lang -> String
publishVideo lang =
    case lang of
        FrFr ->
            "Publier la vidéo"

        _ ->
            "Publish video"


watchVideo : Lang -> String
watchVideo lang =
    case lang of
        FrFr ->
            "Voir la vidéo"

        _ ->
            "Watch video"


watchGosVideo : Lang -> String -> String
watchGosVideo lang gos =
    case lang of
        FrFr ->
            "Voir le grain " ++ gos

        _ ->
            "Watch grain " ++ gos


producing : Lang -> String
producing lang =
    case lang of
        FrFr ->
            "Production de la vidéo en cours..."

        _ ->
            "Producing video..."


publishing : Lang -> String
publishing lang =
    case lang of
        FrFr ->
            "Publication de la vidéo en cours..."

        _ ->
            "Publishing video..."


downloadVideo : Lang -> String
downloadVideo lang =
    case lang of
        FrFr ->
            "Télécharger la vidéo"

        _ ->
            "Download video"


copyVideoUrl : Lang -> String
copyVideoUrl lang =
    case lang of
        FrFr ->
            "Copier l'URL de la vidéo"

        _ ->
            "Copy video URL"


videoSettings : Lang -> String
videoSettings lang =
    case lang of
        FrFr ->
            "Paramètres de la vidéo"

        _ ->
            "Video settings"


privacy : Lang -> Capsule.Privacy -> String
privacy lang p =
    case p of
        Capsule.Private ->
            case lang of
                FrFr ->
                    "privée"

                _ ->
                    "private"

        Capsule.Unlisted ->
            case lang of
                FrFr ->
                    "non répertoriée"

                _ ->
                    "unlisted"

        Capsule.Public ->
            case lang of
                FrFr ->
                    "publique"

                _ ->
                    "public"


privacySettings : Lang -> String
privacySettings lang =
    case lang of
        FrFr ->
            "Paramètres de confidentialité"

        _ ->
            "Privacy settings"


fullscreen : Lang -> String
fullscreen lang =
    case lang of
        FrFr ->
            "Plein écran"

        _ ->
            "Fullscreen"


opacity : Lang -> String
opacity lang =
    case lang of
        FrFr ->
            "Opacité"

        _ ->
            "Opacity"


refreshDevices : Lang -> String
refreshDevices lang =
    case lang of
        FrFr ->
            "Raffraichir la liste des périphériques"

        _ ->
            "Refresh device list"


pdfConvertFailed : Lang -> String
pdfConvertFailed lang =
    case lang of
        FrFr ->
            "Une erreur est survenue. Le numéro de page est-il correct ?"

        _ ->
            "An error happend. Is the page number correct?"


addSlide : Lang -> String
addSlide lang =
    case lang of
        FrFr ->
            "Ajouter un slide"

        _ ->
            "Add a slide"


detectingDevices : Lang -> String
detectingDevices lang =
    case lang of
        FrFr ->
            "Détection des périphériques en cours..."

        _ ->
            "Detecting devices..."


bindingWebcam : Lang -> String
bindingWebcam lang =
    case lang of
        FrFr ->
            "Connection aux périphériques en cours..."

        _ ->
            "Connecting to devices..."


errorDetectingDevices : Lang -> String
errorDetectingDevices lang =
    case lang of
        FrFr ->
            "Erreur lors de la détection les périphériques. La webcam et le micro sont-ils bien autorisés ?"

        _ ->
            "Error while detecting devices. Are webcam and microphone allowed ?"


errorBindingWebcam : Lang -> String
errorBindingWebcam lang =
    case lang of
        FrFr ->
            "Erreur lors de la connexion aux périphériques. La webcam est-elle utilisée par un autre logiciel ?"

        _ ->
            "Error while connecting to devices. Is the webcam used by some other software?"


cancelProduction : Lang -> String
cancelProduction lang =
    case lang of
        FrFr ->
            "Annuler la production"

        _ ->
            "Cancel production"


cancelPublication : Lang -> String
cancelPublication lang =
    case lang of
        FrFr ->
            "Annuler la publication"

        _ ->
            "Cancel publication"


cantUseVideoBecauseNoRecord : Lang -> String
cantUseVideoBecauseNoRecord lang =
    case lang of
        FrFr ->
            "Vous ne pouvez pas incruster la vidéo car il n'y a aucun enregistrement pour ce groupe de slides."

        _ ->
            "You cannot use webcam video because there is no record for this group of slides."


cantUseVideoBecauseAudioOnly : Lang -> String
cantUseVideoBecauseAudioOnly lang =
    case lang of
        FrFr ->
            "Vous ne pouvez pas incruster la vidéo car l'enregistrement ne contient que de l'audio."

        _ ->
            "You cannot use webcam video because the record contains only audio."


exportCapsule : Lang -> String
exportCapsule lang =
    case lang of
        FrFr ->
            "Exporter la capsule"

        _ ->
            "Export capsule"


share : Lang -> String
share lang =
    case lang of
        FrFr ->
            "Partager"

        _ ->
            "Share"


shareCapsuleWith : Lang -> String
shareCapsuleWith lang =
    case lang of
        FrFr ->
            "Partager la capsule avec"

        _ ->
            "Share capsule with"


usernameOrEmail : Lang -> String
usernameOrEmail lang =
    case lang of
        FrFr ->
            "Nom d'utilisateur ou adresse e-mail"

        _ ->
            "Username or email address"


errorSharingCapsule : Lang -> String
errorSharingCapsule lang =
    case lang of
        FrFr ->
            "Erreur lors du partage de la capsule : l'utilisateur existe-t-il ?"

        _ ->
            "Error while sharing capsule: does the user exist?"


people : Lang -> String
people lang =
    case lang of
        FrFr ->
            "Collaborateurs"

        _ ->
            "People"


error404 : Lang -> String
error404 lang =
    case lang of
        FrFr ->
            "Erreur 404"

        _ ->
            "Error 404"


notFound : Lang -> String
notFound lang =
    case lang of
        FrFr ->
            "La page que vous demandez n'as pas été trouvée."

        _ ->
            "The page you requested was not found."


clickHereToGoBackHome : Lang -> String
clickHereToGoBackHome lang =
    case lang of
        FrFr ->
            "Cliquez ici pour retourner à l'accueil."

        _ ->
            "Click here to go back to the home page."


dashboard : Lang -> String
dashboard lang =
    case lang of
        FrFr ->
            "Synthèse"

        _ ->
            "Dashboard"


users : Lang -> String
users lang =
    case lang of
        FrFr ->
            "Utilisateurs"

        _ ->
            "Users"


prev : Lang -> String
prev lang =
    case lang of
        FrFr ->
            "Précédent"

        _ ->
            "Previous"


next : Lang -> String
next lang =
    case lang of
        FrFr ->
            "suivant"

        _ ->
            "Next"


promptSubtitles : Lang -> String
promptSubtitles lang =
    case lang of
        FrFr ->
            "Utiliser le prompteur pour générer les sous-titres"

        _ ->
            "Use prompt text to generate subtitles"


unpublishVideo : Lang -> String
unpublishVideo lang =
    case lang of
        FrFr ->
            "Dépublier la vidéo"

        _ ->
            "Unpublish video"


shortcuts : Lang -> List String
shortcuts lang =
    case lang of
        FrFr ->
            [ "Enregistrer : espace"
            , "Finir l'enregistrement : espace"
            , "Suite : flèche à droite"
            ]

        _ ->
            [ "Record: space"
            , "End record: space"
            , "Next: Right arrow"
            ]


inviteUser : Lang -> String
inviteUser lang =
    case lang of
        FrFr ->
            "Inviter un utilisateur"

        _ ->
            "Invite a User"


enterPasswords : Lang -> String
enterPasswords lang =
    case lang of
        FrFr ->
            "Saisir un mot de passe pour valider l'inscritption à Polymny studio"

        _ ->
            "Enter a password to validate Polymny studio invitation"


deleteUserConfirm : Lang -> String -> String -> String
deleteUserConfirm lang name email =
    case lang of
        FrFr ->
            "Voulez-vous vraiment supprimer l'utilisateur\n " ++ name ++ "<" ++ email ++ "> ?"

        _ ->
            "Do you really want to delete user\n " ++ name ++ "<" ++ email ++ "> ?"


deleteSelf : Lang -> String
deleteSelf lang =
    case lang of
        FrFr ->
            "Vous allez supprimer votre compte. Toutes vos capsules seront supprimées, et les vidéos publiées ne seront plus accessibles. Voulez-vous vraiment continuer ?"

        _ ->
            "You are going to delete your account. All your capsules will be deleted, and the published videos will no longer be accessible. Are you sure you want to continue?"


deleteAccount : Lang -> String
deleteAccount lang =
    case lang of
        FrFr ->
            "Supprimer le compte"

        _ ->
            "Delete the account"


uploadRecordFailed : Lang -> String
uploadRecordFailed lang =
    case lang of
        FrFr ->
            "Échec de l'envoi de l'enregistrement, veuillez recommencer."

        _ ->
            "Record upload failed, please try again."


error : Lang -> String
error lang =
    case lang of
        FrFr ->
            "Erreur"

        _ ->
            "Error"


key : Lang -> String
key lang =
    case lang of
        FrFr ->
            "Key"

        _ ->
            "Key"


keyColor : Lang -> String
keyColor lang =
    case lang of
        FrFr ->
            "Couleur de keying"

        _ ->
            "Keying color"


activateKeying : Lang -> String
activateKeying lang =
    case lang of
        FrFr ->
            "Activer le keying"

        _ ->
            "Activate keying"


activateFade : Lang -> String
activateFade lang =
    case lang of
        FrFr ->
            "Activer le fading"

        _ ->
            "Activate fading"


errorUploadingPdf : Lang -> String
errorUploadingPdf lang =
    case lang of
        FrFr ->
            "Une erreur est survenue lors de l'envoi du PDF."

        _ ->
            "An error occured while uploading the PDF."


grain : Lang -> String
grain lang =
    case lang of
        FrFr ->
            "Grain"

        _ ->
            "Grain"


custom : Lang -> String
custom lang =
    case lang of
        FrFr ->
            "Personnalisé"

        _ ->
            "Custom"


enterNewNameForCapsule : Lang -> String
enterNewNameForCapsule lang =
    case lang of
        FrFr ->
            "Entrez le nouveau nom de la capsule"

        _ ->
            "Enter the new name for the capsule"


createNewProject : Lang -> String
createNewProject lang =
    case lang of
        FrFr ->
            "Créer un nouveau projet"

        _ ->
            "Create new project"


chooseProject : Lang -> String
chooseProject lang =
    case lang of
        FrFr ->
            "Choisir le project"

        _ ->
            "Choose project"


recordsWillBeLost : Lang -> String
recordsWillBeLost lang =
    case lang of
        FrFr ->
            "Les enregistrements non validés seront perdus."

        _ ->
            "Non validated records will be lost."


explainPrivate : Lang -> String
explainPrivate lang =
    case lang of
        FrFr ->
            "la vidéo ne sera visible que par les utilisateurs explicitement autorisées"

        _ ->
            "the video will be visible only by explicitly authorized users"


explainPrivateWarning : Lang -> String
explainPrivateWarning lang =
    case lang of
        FrFr ->
            "cette fonctionnalité n'est pas encore prête : aucun utilisateur ne pourra voir la vidéo à part vous-même"

        _ ->
            "this feature is not ready yet: no users except you will be able to watch the video"


explainUnlisted : Lang -> String
explainUnlisted lang =
    case lang of
        FrFr ->
            "la vidéo ne sera visible que par les personnes connaissant l'URL, Polymny Studio ne partagera pas l'URL de la vidéo"

        _ ->
            "the video will be visible by anyone who knows the URL, Polymny Studio will not share the video's URL"


explainPublic : Lang -> String
explainPublic lang =
    case lang of
        FrFr ->
            "la vidéo sera visible par les personnes connaissant l'URL, Polymny Studio pourrait, dans le futur, partager l'URL de la vidéo via un moteur de recherche, un système de recommandations, etc."

        _ ->
            "the video will be visible by anyone who knows the URL, Polymny Studio may, in the future, share the video's URL via a search engine, a recommendation system, etc."


close : Lang -> String
close lang =
    case lang of
        FrFr ->
            "Fermer"

        _ ->
            "Close"


createGrain : Lang -> String
createGrain lang =
    case lang of
        FrFr ->
            "Créer un grain"

        _ ->
            "Create grain"
