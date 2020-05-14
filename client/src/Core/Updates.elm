module Core.Updates exposing (update)

import Core.Types as Core
import LoggedIn.Types as LoggedIn
import LoggedIn.Updates as LoggedIn
import Login.Types as Login
import Login.Updates as Login
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import NewProject.Types as NewProject
import NewProject.Updates as NewProject
import Preparation.Types as Preparation
import SignUp.Types as SignUp
import SignUp.Updates as SignUp


update : Core.Msg -> Core.FullModel -> ( Core.FullModel, Cmd Core.Msg )
update msg { global, model } =
    case ( msg, model ) of
        -- INNER MESSAGES
        ( Core.Noop, _ ) ->
            ( Core.FullModel global model, Cmd.none )

        ( Core.TimeZoneChanged newTimeZone, _ ) ->
            ( Core.FullModel { global | zone = newTimeZone } model, Cmd.none )

        ( Core.HomeClicked, Core.LoggedIn { session } ) ->
            ( Core.FullModel global
                (Core.LoggedIn
                    { session = session
                    , tab =
                        LoggedIn.Preparation Preparation.Home
                    }
                )
            , Cmd.none
            )

        ( Core.LoginClicked, _ ) ->
            ( Core.FullModel global (Core.Login Login.init), Cmd.none )

        ( Core.LogoutClicked, _ ) ->
            ( Core.FullModel global Core.Home, Cmd.none )

        ( Core.SignUpClicked, _ ) ->
            ( Core.FullModel global (Core.SignUp SignUp.init), Cmd.none )

        ( Core.NewProjectClicked, Core.LoggedIn { session } ) ->
            ( Core.FullModel global
                (Core.LoggedIn
                    { session = session
                    , tab =
                        LoggedIn.Preparation <|
                            Preparation.NewProject NewProject.init
                    }
                )
            , Cmd.none
            )

        ( Core.NewCapsuleClicked project, Core.LoggedIn { session } ) ->
            ( Core.FullModel global
                (Core.LoggedIn
                    { session = session
                    , tab =
                        LoggedIn.Preparation <|
                            Preparation.NewCapsule project NewCapsule.init
                    }
                )
            , Cmd.none
            )

        -- OTHER MODULES MESSAGES
        ( Core.LoginMsg loginMsg, Core.Login loginModel ) ->
            let
                ( m, cmd ) =
                    Login.update loginMsg loginModel
            in
            ( Core.FullModel global m, cmd )

        ( Core.SignUpMsg signUpMsg, Core.SignUp signUpModel ) ->
            let
                ( m, cmd ) =
                    SignUp.update signUpMsg signUpModel
            in
            ( Core.FullModel global (Core.SignUp m), cmd )

        ( Core.LoggedInMsg newProjectMsg, Core.LoggedIn { session, tab } ) ->
            let
                ( m, cmd ) =
                    LoggedIn.update newProjectMsg (LoggedIn.Model session tab)
            in
            ( Core.FullModel global (Core.LoggedIn m), cmd )

        _ ->
            ( Core.FullModel global model, Cmd.none )
