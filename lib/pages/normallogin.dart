import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/register.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mytext.dart';

class NormalLogin extends StatefulWidget {
  const NormalLogin({super.key});

  @override
  State<NormalLogin> createState() => _NormalLoginState();
}

class _NormalLoginState extends State<NormalLogin> {
  late GeneralProvider generalProvider;
  SharedPref sharedPre = SharedPref();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showHidePassword = true;

  @override
  void initState() {
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: MyImage(
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  imagePath: "back.png",
                ),
              ),
              const SizedBox(height: 10),
              MyImage(
                  imagePath: "appicon.png",
                  isAppIcon: true,
                  height: 200,
                  width: 200),
              const SizedBox(height: 30),
              // Welcome Back Text
              MyText(
                  color: Theme.of(context).colorScheme.surface,
                  text: "welcomeback",
                  multilanguage: true,
                  fontsize: 27,
                  maxline: 1,
                  inter: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.left,
                  fontstyle: FontStyle.normal,
                  fontwaight: FontWeight.bold),
              const SizedBox(height: 5),
              // Enter Mobilenumber Text
              MyText(
                  color: gray,
                  text: "enteryouremailandpasswordtologin",
                  multilanguage: true,
                  fontsize: Dimens.textMedium,
                  maxline: 1,
                  inter: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.left,
                  fontstyle: FontStyle.normal,
                  fontwaight: FontWeight.w400),
              const SizedBox(height: 30),
              // Mobile number TextField
              textField(
                  controller: emailController,
                  title: "email",
                  icon: Icons.email,
                  isPassword: false,
                  textInputAction: TextInputAction.next,
                  textInputType: TextInputType.text),
              const SizedBox(height: 15),
              textField(
                  controller: passwordController,
                  title: "password",
                  isPassword: true,
                  icon: Icons.lock,
                  textInputAction: TextInputAction.done,
                  textInputType: TextInputType.text),
              const SizedBox(height: 30),
              loginButton(),
              const SizedBox(height: 20),
              orSection(),
              const SizedBox(height: 20),
              goingRegister(),
            ],
          ),
        ),
      ),
    );
  }

  Widget textField(
      {required TextEditingController controller,
      required String title,
      required icon,
      required isPassword,
      required TextInputAction textInputAction,
      required TextInputType textInputType}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          obscureText: isPassword ? showHidePassword : false,
          textAlignVertical: TextAlignVertical.center,
          obscuringCharacter: "*",
          controller: controller,
          cursorColor: Theme.of(context).colorScheme.surface,
          style: Utils.googleFontStyle(1, 16, FontStyle.normal,
              Theme.of(context).colorScheme.surface, FontWeight.w500),
          keyboardType: textInputType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: gray,
            ),
            suffixIcon: isPassword == true
                ? InkWell(
                    focusColor: transparent,
                    splashColor: transparent,
                    highlightColor: transparent,
                    hoverColor: transparent,
                    onTap: () {
                      setState(() {
                        showHidePassword = !showHidePassword;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      child: Icon(
                        size: 20,
                        showHidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: gray,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            filled: false,
            labelStyle: Utils.googleFontStyle(
                1, 14, FontStyle.normal, gray, FontWeight.w500),
            labelText: Locales.string(context, title),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(color: gray, width: 2),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(color: gray, width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(color: gray, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(color: colorPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _loginButtonGradientColors(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const [colorAccent, colorPrimary]
          : [colorPrimary, homeSearchBarBg(context)];

  Consumer<GeneralProvider> loginButton() {
    return Consumer<GeneralProvider>(
        builder: (context, generalprovider, child) {
      if (generalprovider.isProgressLoading) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.07,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _loginButtonGradientColors(context),
              end: Alignment.topRight,
              begin: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: white,
              strokeWidth: 2.5,
            ),
          ),
        );
      } else {
        return InkWell(
          onTap: () async {
            bool emailValidation = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(emailController.text);

            if (emailController.text.isEmpty) {
              Utils.showSnackbar(context, "pleasenteremail", true);
            } else if (passwordController.text.isEmpty) {
              Utils.showSnackbar(context, "pleaseenteryourpassword", true);
            } else if (passwordController.text.length < 6) {
              Utils.showSnackbar(
                  context, "pleaseenterpasswordonlysixdigit", true);
            } else if (!emailValidation) {
              Utils.showSnackbar(context, "invalidemailaddress", true);
            } else {
              loginApi();
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.07,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: _loginButtonGradientColors(context),
                end: Alignment.topRight,
                begin: Alignment.topLeft,
              ),
            ),
            child: MyText(
                color: white,
                text: "login",
                fontsize: Dimens.textBig,
                maxline: 1,
                multilanguage: true,
                inter: 3,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
                fontwaight: FontWeight.w600),
          ),
        );
      }
    });
  }

  Row orSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 88.0, right: 15.0),
            child: const Divider(
              color: gray,
            ),
          ),
        ),
        MyText(
            color: gray,
            text: "or",
            multilanguage: true,
            fontsize: Dimens.textMedium,
            maxline: 1,
            inter: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
            fontwaight: FontWeight.w400),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 15.0, right: 88.0),
            child: const Divider(
              color: gray,
            ),
          ),
        ),
      ],
    );
  }

  Widget goingRegister() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Register();
            },
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MyText(
              color: gray,
              text: "donthaveanaccount",
              fontsize: Dimens.textSmall,
              maxline: 1,
              fontwaight: FontWeight.w400,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
              multilanguage: true),
          const SizedBox(width: 5),
          MyText(
              color: colorPrimary,
              text: "register",
              fontsize: Dimens.textSmall,
              maxline: 1,
              fontwaight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
              multilanguage: true),
        ],
      ),
    );
  }

  Future<void> loginApi() async {
    generalProvider.setLoading(true);
    await generalProvider.getLogin(Constant.normalLoginType, "",
        emailController.text, passwordController.text, "", "", "", "");

    if (!generalProvider.loading) {
      if (generalProvider.loginModel.status == 200 &&
          (generalProvider.loginModel.result?.length ?? 0) > 0) {
        Utils.saveUserCreds(
          userID: generalProvider.loginModel.result?[0].id.toString(),
          userName: generalProvider.loginModel.result?[0].fullName.toString(),
          userEmail: generalProvider.loginModel.result?[0].email.toString(),
          usercountrycode:
              generalProvider.loginModel.result?[0].countryCode.toString(),
          usercountryname:
              generalProvider.loginModel.result?[0].countryName.toString(),
          userMobile:
              generalProvider.loginModel.result?[0].mobileNumber.toString(),
          userImage: generalProvider.loginModel.result?[0].image.toString(),
          userPremium: generalProvider.loginModel.result?[0].isBuy.toString(),
          userType: generalProvider.loginModel.result?[0].type.toString(),
        );

        generalProvider.setLoading(false);
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Home()),
            (Route route) => false);
      } else {
        generalProvider.setLoading(false);
        if (!mounted) return;
        Utils.showSnackbar(
            context, "${generalProvider.loginModel.message}", false);
      }
    }
  }
}
