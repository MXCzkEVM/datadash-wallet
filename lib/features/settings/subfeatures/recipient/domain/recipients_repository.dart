import 'package:datadashwallet/features/settings/subfeatures/recipient/entities/recipient.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:datadashwallet/core/core.dart';

class RecipientsRepository extends ControlledCacheRepository {
  @override
  final String zone = 'recipients';

  late final Field<List<Recipient>> recipients =
      fieldWithDefault<List<Recipient>>(
    'items',
    [],
    serializer: (t) => t
        .map((e) => {
              'id': e.id,
              'name': e.name,
              'address': e.address,
              'mns': e.mns,
            })
        .toList(),
    deserializer: (t) => (t as List)
        .map((e) => Recipient(
              id: e['id'],
              name: e['name'],
              address: e['address'],
              mns: e['mns'],
            ))
        .toList(),
  );

  List<Recipient> get items => recipients.value;

  void addItem(Recipient item) => recipients.value = [...items, item];

  void removeItem(Recipient item) =>
      recipients.value = items.where((e) => e.id != item.id).toList();
}
