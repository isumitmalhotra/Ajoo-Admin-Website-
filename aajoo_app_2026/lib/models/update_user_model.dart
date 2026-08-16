import 'dart:io';

class UserUpdateRequest {
  final String userFname;
  final String userLname;
  final String userPnumber;
  final String userAddress;
  final String userCity;
  final String userState;
  final String userZipcode;
  final String? docType; 
  final String? docNumber;
  final File? idDoc;

  UserUpdateRequest({
    required this.userFname,
    required this.userLname,
    required this.userPnumber,
    required this.userAddress,
    required this.userCity,
    this.userState = '',
    required this.userZipcode,
    this.docType,
    this.docNumber,
    this.idDoc,
  });



  Map<String, dynamic> toJson() => {
        'user_fname': userFname,
        'user_lname': userLname,
        'user_pnumber': userPnumber,
        'user_address': userAddress,
        'user_city': userCity,
        'user_state': userState,
        'user_zipcode': userZipcode,
        'doc_type': docType,
        'doc_number': docNumber,
        
      };
}
