library firebase_ui;

export 'utils.dart';

import 'package:flutter/material.dart';
import 'login_view.dart';
import 'utils.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen(
      {Key key,
      this.title,
      this.header,
      this.footer,
      this.signUpPasswordCheck,
      this.providers,
      this.color = Colors.white,
      this.twitterConsumerKey,
      this.twitterConsumerSecret,
      @required this.padding,
      this.horizontal = false,
      this.mergeData,
      @required this.showBar,
      @required this.avoidBottomInset})
      : super(key: key);

  final String title;
  final Widget header;
  final Widget footer;
  final List<ProvidersTypes> providers;
  final Color color;
  final bool signUpPasswordCheck;
  final String twitterConsumerKey;
  final String twitterConsumerSecret;
  final bool showBar;
  final bool avoidBottomInset;
  final bool horizontal;
  final EdgeInsets padding;
  final Function mergeData;

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  Widget get _header => widget.header ?? Container();
  Widget get _footer => widget.footer ?? Container();

  bool get _passwordCheck => widget.signUpPasswordCheck ?? false;

  List<ProvidersTypes> get _providers =>
      widget.providers ?? [ProvidersTypes.email];

  @override
  Widget build(BuildContext context) =>  Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header,
          LoginView(
            mergeData:widget.mergeData,
            horizontal: widget.horizontal,
            providers: _providers,
            passwordCheck: _passwordCheck,
            twitterConsumerKey: widget.twitterConsumerKey,
            twitterConsumerSecret: widget.twitterConsumerSecret,
            padding: widget.padding,
          ),
          _footer
        ],
      );
}
