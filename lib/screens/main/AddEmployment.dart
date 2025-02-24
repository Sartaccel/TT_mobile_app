import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:talent_turbo_new/AppColors.dart';
import 'package:talent_turbo_new/AppConstants.dart';
import 'package:talent_turbo_new/Utils.dart';
import 'package:talent_turbo_new/models/candidate_profile_model.dart';
import 'package:talent_turbo_new/models/referral_profile_model.dart';
import 'package:talent_turbo_new/models/user_data_model.dart';
import 'package:http/http.dart' as http;

import '../../models/login_data_model.dart';

class Addemployment extends StatefulWidget {
  final emplomentData;
  const Addemployment({super.key, required this.emplomentData});

  @override
  State<Addemployment> createState() => _AddemploymentState();
}

class _AddemploymentState extends State<Addemployment> {
  final databaseRef =
      FirebaseDatabase.instance.ref().child(AppConstants.APP_NAME);

  final int maxLength = 2000;

  bool isLoading = false;
  bool isEdit = false;

  DateTime startDatems = DateTime.now();

  ReferralData? referralData;
  UserData? retrievedUserData;

  String? _selectedOption = 'No';
  String startYear = '', endYear = '';

  bool _isDesignationValid = true;
  TextEditingController txtDesignationController = TextEditingController();
  String designationErrorMsg = 'Designation cannot be empty';

  bool _isCompanyNameValid = true;
  TextEditingController txtComanyNameController = TextEditingController();
  String companyNameErrorMsg = 'Company name cannot be empty';

  bool isStartDateValid = true;
  bool _startDateSelected = false;

  String? startDateErrorMsg = 'Start date cannot be empty';
  final TextEditingController _startDateController = TextEditingController();

  bool isEndDateValid = true;
  String? endDateErrorMsg = 'End date cannot be empty';
  final TextEditingController _endDateController = TextEditingController();

  bool _isDescriptionValid = true;
  String? descriptionErrorMsg = 'Description cannot be empty';
  final TextEditingController txtDescriptionController =
      TextEditingController();

  bool isWorkTypeValid = true;
  String selectedWorkType = '';

  bool isEmploymentTypeValid = true;
  String selectedEmploymentType = '';

  String email = '';

  Future<void> updateinRTDB(String id, String bodyParams) async {
    final sanitizedEmail = email.replaceAll('.', ',');
    //final snapshot = await databaseRef.child('$sanitizedEmail/notificationSettings').get();
    databaseRef.child('${sanitizedEmail}/employmentData').set({
      'bodyParams': bodyParams,
    });
  }

  Future<void> fetchCandidateProfileData(int profileId, String token) async {
    //final url = Uri.parse(AppConstants.BASE_URL + AppConstants.REFERRAL_PROFILE + profileId.toString());
    final url = Uri.parse(AppConstants.BASE_URL +
        AppConstants.CANDIDATE_PROFILE +
        profileId.toString());

    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      if (response.statusCode == 200) {
        var resOBJ = jsonDecode(response.body);

        String statusMessage = resOBJ['message'];

        if (statusMessage.toLowerCase().contains('success')) {
          final Map<String, dynamic> data = resOBJ['data'];
          //ReferralData referralData = ReferralData.fromJson(data);
          CandidateProfileModel candidateData =
              CandidateProfileModel.fromJson(data);

          await saveCandidateProfileData(candidateData);

          /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => PersonalDetails()),
                (Route<dynamic> route) => route.isFirst, // This will keep Screen 1
          );*/

          Navigator.pop(context);
        }
      } else {
        print(response);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateEmployment() async {
    final url = Uri.parse(AppConstants.BASE_URL +
        AppConstants.ADD_EMPLOYMENT +
        retrievedUserData!.profileId.toString() +
        '/employment');

    final bodyParams = isEdit
        ? {
            "candidateEmployment": [
              {
                "id": widget.emplomentData['id'].toString(),
                "companyName": txtComanyNameController.text,
                "jobTitle": txtDesignationController.text,
                "skillSet": selectedEmploymentType,
                "city": "Nagercoil",
                "stateName": "",
                "employedFrom": _startDateController.text,
                "employedTo": _selectedOption == 'No'
                    ? _endDateController.text
                    : '1970-01-01',
                "leavingReason": txtDescriptionController.text,
                "referenceName": "",
                "referencePhone": "",
                "referenceEmail": "",
                "referenceRelationship": "",
                "is_current": _selectedOption == 'No' ? false : true,
                "countryId": "US",
                "workType": selectedWorkType
                /*"employedFrom1": startYear,
          "employedTo1": endYear*/
              }
            ]
          }
        : {
            "candidateEmployment": [
              {
                "companyName": txtComanyNameController.text,
                "jobTitle": txtDesignationController.text,
                "skillSet": selectedEmploymentType,
                "city": "Nagercoil",
                "stateName": "",
                "employedFrom": _startDateController.text,
                "employedTo": _selectedOption == 'No'
                    ? _endDateController.text
                    : '1970-01-01',
                "leavingReason": txtDescriptionController.text,
                "referenceName": "",
                "referencePhone": "",
                "referenceEmail": "",
                "referenceRelationship": "",
                "is_current": _selectedOption == 'No' ? false : true,
                "countryId": "US",
                "workType": selectedWorkType
                /*"employedFrom1": startYear,
          "employedTo1": endYear*/
              }
            ]
          };

    if (kDebugMode) {
      print('Body Params : ${(bodyParams)}');
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Fluttertoast.showToast(
        //   msg: "No internet connection",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   timeInSecForIosWeb: 1,
        //   backgroundColor: Color(0xff2D2D2D),
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        IconSnackBar.show(
          context,
          label: 'No internet connection',
          snackBarType: SnackBarType.alert,
          backgroundColor: Color(0xff2D2D2D),
          iconColor: Colors.white,
        );
        return; // Exit the function if no internet
      }
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': retrievedUserData!.token
        },
        body: jsonEncode(bodyParams),
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 202) {
        fetchCandidateProfileData(
            retrievedUserData!.profileId, retrievedUserData!.token);
      }
    } catch (e) {
      setState(() {
        if (kDebugMode) {
          print(e);
        }
        isLoading = false;
      });
    }
  }

  DateTime parseDate(String dateString) {
    // Split the date string into its components
    List<String> parts = dateString.split('-');

    // Check if the format is valid
    if (parts.length != 3) {
      throw FormatException('Invalid date format. Use YY-MM-DD.');
    }

    // Parse the year, month, and day
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    // If the year is in 2 digits, adjust it to a 4-digit year
    if (year < 100) {
      year += (year < 70)
          ? 2000
          : 1900; // Assuming 00-69 is 21st century and 70-99 is 20th century
    }

    // Return the DateTime object
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 40,
            decoration: BoxDecoration(color: Color(0xff001B3E)),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 60,
            decoration: BoxDecoration(color: Color(0xff001B3E)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                            height: 50,
                            child: Center(
                                child: Text(
                              'Back',
                              style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 16,
                                  color: Colors.white),
                            ))))
                  ],
                ),
                //SizedBox(width: 80,)
                Text(
                  'Work Experience',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '       ',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
                  child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 25,
                            ),
                            Text(
                              'Current Designation',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff333333)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width) - 20,
                              child: TextField(
                                controller: txtDesignationController,
                                style:
                                    TextStyle(fontSize: 14, fontFamily: 'Lato'),
                                decoration: InputDecoration(
                                    hintText: 'Designation',
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isDesignationValid
                                              ? Colors.grey
                                              : Colors
                                                  .red, // Default border color
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isDesignationValid
                                              ? Colors.blue
                                              : Colors
                                                  .red, // Border color when focused
                                          width: 1),
                                    ),
                                    errorText: _isDesignationValid
                                        ? null
                                        : designationErrorMsg,
                                    // Display error message if invalid
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10)),
                                onChanged: (value) {
                                  // Validate the email here and update _isEmailValid
                                  setState(() {
                                    _isDesignationValid = true;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Text(
                              'Company Name',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff333333)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width) - 20,
                              child: TextField(
                                controller: txtComanyNameController,
                                style:
                                    TextStyle(fontSize: 14, fontFamily: 'Lato'),
                                decoration: InputDecoration(
                                    hintText: 'Company',
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isCompanyNameValid
                                              ? Colors.grey
                                              : Colors
                                                  .red, // Default border color
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isCompanyNameValid
                                              ? Colors.blue
                                              : Colors
                                                  .red, // Border color when focused
                                          width: 1),
                                    ),
                                    errorText: _isCompanyNameValid
                                        ? null
                                        : companyNameErrorMsg,
                                    // Display error message if invalid
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10)),
                                onChanged: (value) {
                                  // Validate the email here and update _isEmailValid
                                  setState(() {
                                    _isCompanyNameValid = true;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              'Is this your current company?',
                              style:
                                  TextStyle(fontSize: 14, fontFamily: 'Lato'),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<String>(
                                      value: 'Yes',
                                      groupValue: _selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedOption = value;
                                          _endDateController.text = '';
                                          isEndDateValid = true;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Yes',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Lato'),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'No',
                                      groupValue: _selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          isEndDateValid = true;
                                          _selectedOption = value;
                                        });
                                      },
                                    ),
                                    Text(
                                      'No',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Lato'),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 80),
                              ],
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                            fontSize: 14, fontFamily: 'Lato'),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      TextField(
                                        controller: _startDateController,
                                        decoration: InputDecoration(
                                            suffixIcon:
                                                Icon(Icons.calendar_today),
                                            hintText: 'From',
                                            border: OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: isStartDateValid
                                                      ? Colors.grey
                                                      : Colors
                                                          .red, // Default border color
                                                  width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: isStartDateValid
                                                      ? Colors.blue
                                                      : Colors
                                                          .red, // Border color when focused
                                                  width: 1),
                                            ),
                                            errorText: isStartDateValid
                                                ? null
                                                : startDateErrorMsg, // Display error message if invalid
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 10)),
                                        readOnly: true,
                                        onTap: () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now()
                                                      .subtract(
                                                          Duration(days: 1)),
                                                  firstDate: DateTime(2000),
                                                  //lastDate: DateTime(2101),
                                                  lastDate: DateTime.now()
                                                      .subtract(
                                                          Duration(days: 1)),
                                                  initialDatePickerMode:
                                                      DatePickerMode.year);
                                          if (pickedDate != null) {
                                            setState(() {
                                              isStartDateValid = true;
                                              _startDateSelected = true;
                                              startDatems = pickedDate;
                                              //_startDateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                              _startDateController.text =
                                                  "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                              startYear =
                                                  '${pickedDate.month}-${pickedDate.year}';
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    width: 10), // Space between the two fields
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                            fontSize: 14, fontFamily: 'Lato'),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      TextField(
                                        controller: _endDateController,
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          hintText: _selectedOption == 'No'
                                              ? 'To'
                                              : 'Present',
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                          border: OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: isEndDateValid
                                                    ? Colors.grey
                                                    : Colors
                                                        .red, // Default border color
                                                width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: isEndDateValid
                                                    ? Colors.blue
                                                    : Colors
                                                        .red, // Border color when focused
                                                width: 1),
                                          ),
                                          errorText: isEndDateValid
                                              ? null
                                              : endDateErrorMsg,
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          if (_selectedOption == 'No' &&
                                              _startDateSelected == true) {
                                            DateTime? pickedDate =
                                                await showDatePicker(
                                                    context: context,
                                                    initialDate: startDatems,
                                                    firstDate: startDatems,
                                                    lastDate: DateTime.now(),
                                                    initialDatePickerMode:
                                                        DatePickerMode.year);
                                            if (pickedDate != null) {
                                              setState(() {
                                                isEndDateValid = true;
                                                //_endDateController.text ="${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                                _endDateController.text =
                                                    "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                                //_endDateController.text ="${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                                endYear =
                                                    '${pickedDate.month}-${pickedDate.year}';
                                              });
                                            }
                                          } else if (_selectedOption == 'No' &&
                                              _startDateSelected == false) {
                                            // Fluttertoast.showToast(
                                            //   msg: 'Please select start date first',
                                            //   toastLength: Toast.LENGTH_SHORT,
                                            //   gravity: ToastGravity.BOTTOM,
                                            //   timeInSecForIosWeb: 1,
                                            //   backgroundColor: Color(0xff2D2D2D),
                                            //   textColor: Colors.white,
                                            //   fontSize: 16.0,
                                            // );
                                            IconSnackBar.show(
                                              context,
                                              label:
                                                  'Please select start date first',
                                              snackBarType: SnackBarType.alert,
                                              backgroundColor:
                                                  Color(0xff2D2D2D),
                                              iconColor: Colors.white,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Text(
                              'Work type',
                              style:
                                  TextStyle(fontSize: 14, fontFamily: 'Lato'),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1,
                                      color: isWorkTypeValid
                                          ? Colors.grey
                                          : Colors.red),
                                  borderRadius: BorderRadius.circular(10)),
                              width: (MediaQuery.of(context).size.width) - 20,
                              child: InkWell(
                                onTap: () {
                                  showMaterialModalBottomSheet(
                                    isDismissible: true,
                                    context: context,
                                    builder: (context) => Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 30, horizontal: 10),
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            //leading: Icon(Icons.visibility_outlined),
                                            title: Text('On Site'),
                                            onTap: () {
                                              setState(() {
                                                selectedWorkType = 'On Site';
                                                isWorkTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.refresh),
                                            title: Text('Hybrid'),
                                            onTap: () {
                                              setState(() {
                                                selectedWorkType = 'Hybrid';
                                                isWorkTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.download),
                                            title: Text('Work from home'),
                                            onTap: () {
                                              setState(() {
                                                selectedWorkType =
                                                    'Work from home';
                                                isWorkTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedWorkType.isEmpty
                                        ? 'Select your work type'
                                        : selectedWorkType,
                                    style: TextStyle(color:Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Text(
                              'Employment Type',
                              style:
                                  TextStyle(fontSize: 14, fontFamily: 'Lato'),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1,
                                      color: isWorkTypeValid
                                          ?Colors.grey
                                          : Colors.red),
                                  borderRadius: BorderRadius.circular(10)),
                              width: (MediaQuery.of(context).size.width) - 20,
                              child: InkWell(
                                onTap: () {
                                  showMaterialModalBottomSheet(
                                    isDismissible: true,
                                    context: context,
                                    builder: (context) => Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 30, horizontal: 10),
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            //leading: Icon(Icons.visibility_outlined),
                                            title: Text('Full time'),
                                            onTap: () {
                                              setState(() {
                                                selectedEmploymentType =
                                                    'Full time';
                                                isEmploymentTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.refresh),
                                            title: Text('Part time'),
                                            onTap: () {
                                              setState(() {
                                                selectedEmploymentType =
                                                    'Part time';
                                                isEmploymentTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.download),
                                            title: Text('Internship'),
                                            onTap: () {
                                              setState(() {
                                                selectedEmploymentType =
                                                    'Internship';
                                                isEmploymentTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.download),
                                            title: Text('Freelance'),
                                            onTap: () {
                                              setState(() {
                                                selectedEmploymentType =
                                                    'Freelance';
                                                isEmploymentTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            //leading: Icon(Icons.download),
                                            title: Text('Self-employed'),
                                            onTap: () {
                                              setState(() {
                                                selectedEmploymentType =
                                                    'Self-employed';
                                                isEmploymentTypeValid = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedEmploymentType.isEmpty
                                        ? 'Select your employment type'
                                        : selectedEmploymentType,
                                    style: TextStyle(color: Color(0xff7D7C7C)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            Text(
                              'Description',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff333333)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width) - 20,
                              child: TextField(
                                maxLines: 4,
                                maxLength: maxLength,
                                controller: txtDescriptionController,
                                style:
                                    TextStyle(fontSize: 14, fontFamily: 'Lato'),
                                decoration: InputDecoration(
                                    hintText: 'Your work experience',
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isDescriptionValid
                                              ? Colors.grey
                                              : Colors
                                                  .red, // Default border color
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: _isDescriptionValid
                                              ? Colors.blue
                                              : Colors
                                                  .red, // Border color when focused
                                          width: 1),
                                    ),
                                    errorText: _isDescriptionValid
                                        ? null
                                        : descriptionErrorMsg,
                                    // Display error message if invalid
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10)),
                                onChanged: (value) {
                                  // Validate the email here and update _isEmailValid
                                  setState(() {
                                    _isDescriptionValid = true;
                                  });
                                },
                              ),
                            ),
                            isLoading
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    child: Center(
                                      child: Visibility(
                                        visible: isLoading,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: 30,
                                            ),
                                            LoadingAnimationWidget
                                                .fourRotatingDots(
                                              color: AppColors.primaryColor,
                                              size: 40,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            SizedBox(
                              height: 25,
                            ),
                            InkWell(
                              onTap: () {
                                if ((_selectedOption == 'No' &&
                                        _endDateController.text.isEmpty) ||
                                    txtDesignationController.text.isEmpty ||
                                    txtComanyNameController.text.isEmpty ||
                                    txtDescriptionController.text.isEmpty ||
                                    _startDateController.text.isEmpty ||
                                    selectedWorkType.isEmpty ||
                                    selectedEmploymentType.isEmpty) {
                                  if (txtDesignationController.text.isEmpty) {
                                    setState(() {
                                      _isDesignationValid = false;
                                    });
                                  }

                                  if (txtComanyNameController.text.isEmpty) {
                                    setState(() {
                                      _isCompanyNameValid = false;
                                    });
                                  }

                                  if (_startDateController.text.isEmpty) {
                                    setState(() {
                                      isStartDateValid = false;
                                    });
                                  }

                                  if (_selectedOption == 'No' &&
                                      _endDateController.text.isEmpty) {
                                    setState(() {
                                      isEndDateValid = false;
                                    });
                                  }

                                  if (selectedWorkType.isEmpty) {
                                    setState(() {
                                      isWorkTypeValid = false;
                                    });
                                  }

                                  if (selectedEmploymentType.isEmpty) {
                                    setState(() {
                                      isEmploymentTypeValid = false;
                                    });
                                  }

                                  if (txtDescriptionController.text.isEmpty) {
                                    setState(() {
                                      _isDescriptionValid = false;
                                    });
                                  }
                                } else {
                                  if (kDebugMode) {
                                    print(
                                        'Performing operation................');
                                  }

                                  if (isLoading == false) {
                                    updateEmployment();
                                  }
                                }
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 44,
                                margin: EdgeInsets.symmetric(horizontal: 0),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Center(
                                  child: Text(
                                    'Save',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          ]))))
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchProfileFromPref();

    if (widget.emplomentData != null) {
      setState(() {
        isEdit = true;
        txtDesignationController.text = widget.emplomentData['jobTitle'];
        txtComanyNameController.text = widget.emplomentData['companyName'];
        _startDateController.text = widget.emplomentData['employedFrom'];
        _endDateController.text =
            widget.emplomentData['employedTo'] == '1970-01-01'
                ? ''
                : widget.emplomentData['employedTo'];
        isStartDateValid = true;
        isEndDateValid = true;
        _startDateSelected = true;
        startDatems = parseDate(widget.emplomentData['employedFrom']);
        _selectedOption =
            widget.emplomentData['employedTo'] == '1970-01-01' ? 'Yes' : 'No';

        selectedWorkType =
            (widget.emplomentData['workType'] ?? '').toString().isEmpty
                ? 'On Site'
                : widget.emplomentData['workType'] ?? '';
        selectedEmploymentType =
            (widget.emplomentData['skillSet'] ?? '').toString().isEmpty
                ? 'Full time'
                : widget.emplomentData['skillSet'] ?? '';
        txtDescriptionController.text =
            (widget.emplomentData['leavingReason'] ?? '').toString().isEmpty
                ? 'test'
                : widget.emplomentData['leavingReason'] ?? '';

        if (selectedEmploymentType.toLowerCase().contains('boot')) {
          selectedEmploymentType = '';
        }
      });
    }
  }

  Future<void> fetchProfileFromPref() async {
    ReferralData? _referralData = await getReferralProfileData();
    UserData? _retrievedUserData = await getUserData();
    UserCredentials? loadedCredentials =
        await UserCredentials.loadCredentials();
    setState(() {
      referralData = _referralData;
      retrievedUserData = _retrievedUserData;
      if (loadedCredentials != null) {
        email = loadedCredentials.username;
      }
    });
  }
}
