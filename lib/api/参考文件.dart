// 这个是从其他项目复制来的，仅供参考，就是告诉ai这个api文件夹下是干啥的
// api文件夹下的文件是用来封装与后端API交互的函数，每个文件对应一个功能模块，它们负责发送网络请求、处理响应数据，并将数据转换为业务代码可以直接使用的类型。
// 登录接口API

// import 'package:hm_shop/constants/index.dart';
// import 'package:hm_shop/utils/DioRequest.dart';
// import 'package:hm_shop/viewmodels/user.dart';

// Future<UserInfo> loginAPI(Map<String,dynamic> data) async{
//   return UserInfo.fromJSON(
//     await dioRequest.post(HttpConstants.LOGIN,data: data),
//   );

// }
// Future<UserInfo> getUserInfoAPI() async{
//   return UserInfo.fromJSON(
//     await dioRequest.get(HttpConstants.USER_PROFILE),
//   );
// }