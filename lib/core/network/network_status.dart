abstract class NetworkStatus {
  bool get isOnline;
}

class AlwaysOnlineNetworkStatus implements NetworkStatus {
  const AlwaysOnlineNetworkStatus();

  @override
  bool get isOnline => true;
}