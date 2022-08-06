import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'CropperScreen.dart';

final userNameStateProvider = StateProvider<String>((ref) {
  return "";
});

final passwordStateProvider = StateProvider<String>((ref) {
  return "";
});

final isButtonDisableStateProvider = StateProvider<bool>((ref) {
  String userName = ref.watch(userNameStateProvider);
  String password = ref.watch(passwordStateProvider);
  return userName.isEmpty || password.isEmpty;
});

class HomeScreen extends ConsumerWidget {

  String versionNumber = '0.04';

  @override
  // 2. build() method has an extra [WidgetRef] argument
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. watch the counterStateProvider
    final String userName = ref.watch(userNameStateProvider);
    final String password = ref.watch(passwordStateProvider);
    final bool isButtonDisabled = ref.watch(isButtonDisableStateProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
          ),
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main-background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
              decoration: new BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.75),
          )),
          Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(children: <Widget>[
                ListView(
                  children: <Widget>[
                    SizedBox(
                      height: 35,
                    ),
                    Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10,
                          top: 25,
                          right: 10,
                          bottom: 0,
                        ),
                        child: const Text(
                          'Image Gender Classifier',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 28),
                        )),
                    Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          'Deeper Learning',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 26),
                        )),
                    Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(1),
                        child: Text(
                          'Version ${versionNumber}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 13),
                        )),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        )),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        style: TextStyle(color: Theme.of(context).hintColor),
                        onChanged: (value) => ref.read(userNameStateProvider.state).state = value,
                        decoration: const InputDecoration(
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            gapPadding: 0.0,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black26, width: 3),
                          ),
                          labelText: 'User Name',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: TextField(
                        style: TextStyle(color: Theme.of(context).hintColor),
                        onChanged: (value) => ref.read(passwordStateProvider.state).state = value,
                        decoration: const InputDecoration(
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(color:Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            gapPadding: 0.0,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            borderSide: BorderSide(color: Colors.black26, width: 3),
                          ),
                          labelText: 'Password',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
//forgot password screen
                      },
                      child: const Text(
                        'Forgot Password',
                      ),
                    ),
                    Container(
                        height: 50,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(64, 174, 237, 0.85),
                            textStyle: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: isButtonDisabled
                              ? null
                              : () async {
// ref.read(userProvider).user = "Steve";
                                  Navigator.push(
                                    context,
                                    //MaterialPageRoute(builder: (context) => CameraScreen()),
                                    MaterialPageRoute(builder: (context) => CropperScreen()),
                                  );
                                },
                          child: const Text('Login', style: TextStyle(color: Colors.white)),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Does not have account?'),
                        TextButton(
                          child: const Text(
                            'Sign in',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          onPressed: () {
//signup screen
                          },
                        )
                      ],
                    ),
                  ],
                )
              ])),
        ],
      ),
    );
  }
}
