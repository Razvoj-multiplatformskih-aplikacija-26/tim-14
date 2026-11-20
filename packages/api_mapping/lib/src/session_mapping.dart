import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'accepted.dart';

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.name);
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(id: UserId(id), name: name, role: byName(Role.values, role));
}
