import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'l10n/localization.dart';
import 'utils.dart';

class SignUpView extends StatefulWidget {
  final String email;
  final bool passwordCheck;
  final bool linkIfAnonymous;
  final Function onAuthenticating;

  SignUpView(this.email, this.passwordCheck, this.onAuthenticating, {this.linkIfAnonymous=true, Key key}) : super(key: key);

  @override
  _SignUpViewState createState() => new _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {

  _SignUpViewState() {
  }
  final _formKey = GlobalKey<FormState>();

  TextEditingController _controllerEmail;
  TextEditingController _controllerDisplayName;
  TextEditingController _controllerPassword;
  TextEditingController _controllerCheckPassword;

  final FocusNode _focusPassword = FocusNode();

  bool _valid = false;

  @override
  dispose() {
    _focusPassword.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _controllerEmail = new TextEditingController(text: widget.email);
    _controllerDisplayName = new TextEditingController();
    _controllerPassword = new TextEditingController();
    _controllerCheckPassword = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    _controllerEmail.text = widget.email;
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        title: new Text(FFULocalizations.of(context).signUpTitle),
        elevation: 4.0,
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: new ListView(  
                  children: <Widget>[
                    const SizedBox(height: 8.0),
                    new TextField(
                      controller: _controllerDisplayName,
                      autofocus: false,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      onChanged: _checkValid,
                      onSubmitted: _submitDisplayName,
                      decoration: new InputDecoration(
                          labelText: FFULocalizations.of(context).nameLabel),
                    ),
                    const SizedBox(height: 8.0),
                    new TextFormField(
                      controller: _controllerPassword,
                      obscureText: true,
                      autocorrect: false,
                      validator: (value) {
                        if (value.length < 6) {
                          return 'Password should be at least 8 chars long.';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        _formKey.currentState.validate();
                      },
                      focusNode: _focusPassword,
                      decoration: new InputDecoration(
                          labelText:
                              FFULocalizations.of(context).passwordLabel),
                    ),
                    !widget.passwordCheck
                        ? new Container()
                        : new TextField(
                            controller: _controllerCheckPassword,
                            obscureText: true,
                            autocorrect: false,
                            decoration: new InputDecoration(
                                labelText: FFULocalizations.of(context)
                                    .passwordCheckLabel),
                          ),
                  ],
                ),
              ));
        },
      ),
      persistentFooterButtons: <Widget>[
        new ButtonBar(
          alignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new FlatButton(
                onPressed: _valid ? () => _connexion(context) : null,
                child: new Row(
                  children: <Widget>[
                    new Text(FFULocalizations.of(context).saveLabel),
                  ],
                )),
          ],
        )
      ],
    );
  }

  _submitDisplayName(String submitted) {
    FocusScope.of(context).requestFocus(_focusPassword);
  }

  _submit(String submitted) {
    _connexion(context);
  }

  _connexion(BuildContext context) async {
    if (widget.passwordCheck &&
        _controllerPassword.text != _controllerCheckPassword.text) {
      showErrorDialog(context, FFULocalizations.of(context).passwordCheckError);
      return;
    }

    if (!_formKey.currentState.validate()) {
      return;
    }

    FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      if(widget.onAuthenticating != null) {
          widget.onAuthenticating();
      }
      FirebaseUser user = await _auth.currentUser();
      if(user?.isAnonymous == true) {
        print("User currently anonymously authenticated");
      }
      
      if(widget.linkIfAnonymous) {
        if(user != null) {
          var credential = EmailAuthCredential(
            email: _controllerEmail.text,
            password: _controllerPassword.text);
            try {
              AuthResult authResult = await user.linkWithCredential(credential);
              user = authResult.user;
              print("Linked anonymous account to UID ${user.uid}");
              await _auth.signOut();
            } catch(err) {
              // TODO - if link fails, need to notify user
            } finally {
              AuthResult authResult = await _auth.signInWithEmailAndPassword(email: _controllerEmail.text, password: _controllerPassword.text);
              user = authResult.user;
              print("Signed in user ${user.uid}");
            }
        }
      } 

      if(user == null) {
        print("No anonymous account present, creating user with email and password.");
        AuthResult authResult = await _auth.createUserWithEmailAndPassword(
          email: _controllerEmail.text,
          password: _controllerPassword.text,
        );
        user = authResult.user;
      }
      try {
        var userUpdateInfo = new UserUpdateInfo();
        userUpdateInfo.displayName = _controllerDisplayName.text;
        await user.updateProfile(userUpdateInfo);
        if(mounted)
          Navigator.pop(context, true);
      } catch (e, st) {
        print(e);
        print(st);
        showErrorDialog(context, e.details);
      }
    } catch (e, st) {
      print(e);
      print(st);
      String msg = FFULocalizations.of(context).passwordLengthMessage;
      showErrorDialog(context, msg);
    }
  }

  void _checkValid(String value) {
    setState(() {
      _valid = _controllerDisplayName.text.isNotEmpty;
    });
  }
}
