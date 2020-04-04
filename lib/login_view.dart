import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_twitter/flutter_twitter.dart';

import 'email_view.dart';
import 'utils.dart';

class LoginView extends StatefulWidget {
  final List<ProvidersTypes> providers;
  final bool passwordCheck;
  final String twitterConsumerKey;
  final String twitterConsumerSecret;
  final EdgeInsets padding;
  final bool horizontal;
  final bool linkIfAnonymous;
  final Function mergeData;

  LoginView(
      {Key key,
      @required this.providers,
      this.passwordCheck,
      this.twitterConsumerKey,
      this.twitterConsumerSecret,
      this.horizontal = false,
      this.linkIfAnonymous = true,
      this.mergeData,
      @required this.padding})
      : super(key: key);

  @override
  _LoginViewState createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<ProvidersTypes, ButtonDescription> _buttons;

  _handleEmailSignIn() async {
    String value = await Navigator.of(context)
        .push(new MaterialPageRoute<String>(builder: (BuildContext context) {
      return new EmailView(widget.passwordCheck);
    }));

    if (value != null) {
      _followProvider(value);
    }
  }


  _handleGoogleSignIn() async {
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        try {
          AuthCredential credential = GoogleAuthProvider.getCredential(
              idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
          _signInOrLinkWithAnonymous(credential);
        } catch (e, st) {
          print("Error handling Google signin : $e");
          print(st);
          showErrorDialog(context, e.details);
        }
    }
  }

  Future _signInOrLinkWithAnonymous(AuthCredential credential) async {
    var prevUser = await _auth.currentUser();
    if(prevUser?.isAnonymous == true)
      print("Current user authenticated anonymously");
    var authResult = await _auth.signInWithCredential(credential);
    print("Signed in user : ${authResult.user} with new credentials : $credential");
    if(widget.linkIfAnonymous && prevUser != null && widget.mergeData != null) {
      widget.mergeData(prevUser, authResult.user);
    }
    return;
  }

  // _handleFacebookSignin() async {
  //   FacebookLoginResult result =
  //       await facebookLogin.logIn(['email']);
  //   if (result.accessToken != null) {
  //     try {
  //       AuthCredential credential = FacebookAuthProvider.getCredential(
  //           accessToken: result.accessToken.token);
  //       _signInOrLinkWithAnonymous(credential);
  //       } catch (e) {
  //       showErrorDialog(context, e.details);
  //     }
  //   }
  // }

  _handleTwitterSignin() async {
    var twitterLogin = new TwitterLogin(
      consumerKey: widget.twitterConsumerKey,
      consumerSecret: widget.twitterConsumerSecret,
    );

    final TwitterLoginResult result = await twitterLogin.authorize();

    switch (result.status) {
      case TwitterLoginStatus.loggedIn:
        AuthCredential credential = TwitterAuthProvider.getCredential(
            authToken: result.session.token,
            authTokenSecret: result.session.secret);
        await _auth.signInWithCredential(credential);
        break;
      case TwitterLoginStatus.cancelledByUser:
        showErrorDialog(context, 'Login cancelled.');
        break;
      case TwitterLoginStatus.error:
        showErrorDialog(context, result.errorMessage);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _buttons = {
      // ProvidersTypes.facebook:
      //     providersDefinitions(context)[ProvidersTypes.facebook]
      //         .copyWith(onSelected: _handleFacebookSignin),
      ProvidersTypes.google:
          providersDefinitions(context)[ProvidersTypes.google]
              .copyWith(onSelected: _handleGoogleSignIn),
      ProvidersTypes.twitter:
          providersDefinitions(context)[ProvidersTypes.twitter]
              .copyWith(onSelected: _handleTwitterSignin),
      ProvidersTypes.email: providersDefinitions(context)[ProvidersTypes.email]
          .copyWith(onSelected: _handleEmailSignIn),
    };

    var providerWidgets = widget.providers.map((p) {
      if(!_buttons.containsKey(p))
        return Container();
      return Padding(
          padding: widget.padding,
          child:_buttons[p]);
    }).toList();
    
    var wrapper = widget.horizontal ?  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children:providerWidgets) : Column(
        mainAxisSize: MainAxisSize.min,
        children:providerWidgets);
    
    return wrapper;
  }

  void _followProvider(String value) {
    ProvidersTypes provider = stringToProvidersType(value);
    // if (provider == ProvidersTypes.facebook) {
    //   _handleFacebookSignin();
    // } else 
    
    if (provider == ProvidersTypes.google) {
      _handleGoogleSignIn();
    } else if (provider == ProvidersTypes.twitter) {
      _handleTwitterSignin();
    }
  }
}
