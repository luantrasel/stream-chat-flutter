import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_chat/stream_chat.dart';

import 'stream_chat_core.dart';

/// Widget dedicated to the management of a users list with pagination.
///
/// [UsersBloc] can be access at anytime by using the static [of] method
/// using Flutter's [BuildContext].
///
/// API docs: https://getstream.io/chat/docs/flutter-dart/init_and_users/
class UsersBloc extends StatefulWidget {
  /// Instantiate a new [UsersBloc]. The parameter [child] must be supplied and
  /// not null.
  const UsersBloc({
    Key key,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  /// The widget child
  final Widget child;

  @override
  UsersBlocState createState() => UsersBlocState();

  /// Use this method to get the current [UsersBlocState] instance
  static UsersBlocState of(BuildContext context) {
    UsersBlocState state;

    state = context.findAncestorStateOfType<UsersBlocState>();

    if (state == null) {
      throw Exception('You must have a UsersBloc widget as ancestor');
    }

    return state;
  }
}

/// The current state of the [UsersBloc]
class UsersBlocState extends State<UsersBloc>
    with AutomaticKeepAliveClientMixin {
  /// The current users list
  List<User> get users => _usersController.value;

  /// The current users list as a stream
  Stream<List<User>> get usersStream => _usersController.stream;

  final BehaviorSubject<List<User>> _usersController = BehaviorSubject();

  final BehaviorSubject<bool> _queryUsersLoadingController =
      BehaviorSubject.seeded(false);

  /// The stream notifying the state of queryUsers call
  Stream<bool> get queryUsersLoading => _queryUsersLoadingController.stream;

  /// The Query Users method allows you to search for users and see if they are
  /// online/offline.
  /// [API Reference](https://getstream.io/chat/docs/flutter-dart/query_users/?language=dart)
  Future<void> queryUsers({
    Map<String, dynamic> filter,
    List<SortOption> sort,
    Map<String, dynamic> options,
    PaginationParams pagination,
  }) async {
    final client = StreamChatCore.of(context).client;

    if (client.state?.user == null ||
        _queryUsersLoadingController.value == true) {
      return;
    }
    _queryUsersLoadingController.add(true);
    try {
      final clear = pagination == null ||
          pagination.offset == null ||
          pagination.offset == 0;

      final oldUsers = List<User>.from(users ?? []);

      final usersResponse = await client.queryUsers(
        filter: filter,
        sort: sort,
        options: options,
        pagination: pagination,
      );

      if (clear) {
        _usersController.add(usersResponse.users);
      } else {
        final temp = oldUsers + usersResponse.users;
        _usersController.add(temp);
      }

      _queryUsersLoadingController.add(false);
    } catch (err, stackTrace) {
      _queryUsersLoadingController.addError(err, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void dispose() {
    _usersController.close();
    _queryUsersLoadingController.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
