// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i48;
import 'package:deemusiq/models/metadata/metadata.dart' as _i50;
import 'package:deemusiq/pages/account/account.dart' as _i2;
import 'package:deemusiq/pages/album/album.dart' as _i3;
import 'package:deemusiq/pages/artist/artist.dart' as _i4;
import 'package:deemusiq/pages/catalog/catalog.dart' as _i6;
import 'package:deemusiq/pages/connect/connect.dart' as _i8;
import 'package:deemusiq/pages/connect/control/control.dart' as _i7;
import 'package:deemusiq/pages/getting_started/getting_started.dart' as _i10;
import 'package:deemusiq/pages/home/home.dart' as _i12;
import 'package:deemusiq/pages/home/sections/section_items.dart' as _i11;
import 'package:deemusiq/pages/lastfm_login/lastfm_login.dart' as _i13;
import 'package:deemusiq/pages/library/library.dart' as _i14;
import 'package:deemusiq/pages/library/user_albums.dart' as _i42;
import 'package:deemusiq/pages/library/user_artists.dart' as _i43;
import 'package:deemusiq/pages/library/user_downloads.dart' as _i44;
import 'package:deemusiq/pages/library/user_local_tracks/local_folder.dart'
    as _i17;
import 'package:deemusiq/pages/library/user_local_tracks/user_local_tracks.dart'
    as _i45;
import 'package:deemusiq/pages/library/user_playlists.dart' as _i46;
import 'package:deemusiq/pages/lyrics/lyrics.dart' as _i19;
import 'package:deemusiq/pages/lyrics/mini_lyrics.dart' as _i20;
import 'package:deemusiq/pages/player/lyrics.dart' as _i21;
import 'package:deemusiq/pages/player/queue.dart' as _i22;
import 'package:deemusiq/pages/player/sources.dart' as _i23;
import 'package:deemusiq/pages/playlist/liked_playlist.dart' as _i15;
import 'package:deemusiq/pages/playlist/playlist.dart' as _i24;
import 'package:deemusiq/pages/profile/profile.dart' as _i25;
import 'package:deemusiq/pages/root/root_app.dart' as _i27;
import 'package:deemusiq/pages/search/search.dart' as _i28;
import 'package:deemusiq/pages/settings/about.dart' as _i1;
import 'package:deemusiq/pages/settings/blacklist.dart' as _i5;
import 'package:deemusiq/pages/settings/logs.dart' as _i18;
import 'package:deemusiq/pages/settings/metadata/metadata_form.dart' as _i29;
import 'package:deemusiq/pages/settings/scrobbling/scrobbling.dart' as _i32;
import 'package:deemusiq/pages/settings/settings.dart' as _i31;
import 'package:deemusiq/pages/stats/albums/albums.dart' as _i33;
import 'package:deemusiq/pages/stats/artists/artists.dart' as _i34;
import 'package:deemusiq/pages/stats/fees/fees.dart' as _i38;
import 'package:deemusiq/pages/stats/minutes/minutes.dart' as _i35;
import 'package:deemusiq/pages/stats/playlists/playlists.dart' as _i37;
import 'package:deemusiq/pages/stats/stats.dart' as _i36;
import 'package:deemusiq/pages/stats/streams/streams.dart' as _i39;
import 'package:deemusiq/pages/track/track.dart' as _i41;
import 'package:deemusiq/pages/wallet/creators_supported.dart' as _i9;
import 'package:deemusiq/pages/wallet/leaderboard.dart' as _i26;
import 'package:deemusiq/pages/wallet/linked_accounts.dart' as _i16;
import 'package:deemusiq/pages/wallet/token_store.dart' as _i40;
import 'package:deemusiq/pages/wallet/wallet.dart' as _i47;
import 'package:flutter/material.dart' as _i49;
import 'package:shadcn_flutter/shadcn_flutter.dart' as _i51;

/// generated route for
/// [_i1.AboutDeeMusiqPage]
class AboutDeeMusiqRoute extends _i48.PageRouteInfo<void> {
  const AboutDeeMusiqRoute({List<_i48.PageRouteInfo>? children})
    : super(AboutDeeMusiqRoute.name, initialChildren: children);

  static const String name = 'AboutDeeMusiqRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutDeeMusiqPage();
    },
  );
}

/// generated route for
/// [_i2.AccountPage]
class AccountRoute extends _i48.PageRouteInfo<void> {
  const AccountRoute({List<_i48.PageRouteInfo>? children})
    : super(AccountRoute.name, initialChildren: children);

  static const String name = 'AccountRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i2.AccountPage();
    },
  );
}

/// generated route for
/// [_i3.AlbumPage]
class AlbumRoute extends _i48.PageRouteInfo<AlbumRouteArgs> {
  AlbumRoute({
    _i49.Key? key,
    required String id,
    required _i50.DeeMusiqSimpleAlbumObject album,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         AlbumRoute.name,
         args: AlbumRouteArgs(key: key, id: id, album: album),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'AlbumRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AlbumRouteArgs>();
      return _i3.AlbumPage(key: args.key, id: args.id, album: args.album);
    },
  );
}

class AlbumRouteArgs {
  const AlbumRouteArgs({this.key, required this.id, required this.album});

  final _i49.Key? key;

  final String id;

  final _i50.DeeMusiqSimpleAlbumObject album;

  @override
  String toString() {
    return 'AlbumRouteArgs{key: $key, id: $id, album: $album}';
  }
}

/// generated route for
/// [_i4.ArtistPage]
class ArtistRoute extends _i48.PageRouteInfo<ArtistRouteArgs> {
  ArtistRoute({
    required String artistId,
    _i49.Key? key,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         ArtistRoute.name,
         args: ArtistRouteArgs(artistId: artistId, key: key),
         rawPathParams: {'id': artistId},
         initialChildren: children,
       );

  static const String name = 'ArtistRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ArtistRouteArgs>(
        orElse: () => ArtistRouteArgs(artistId: pathParams.getString('id')),
      );
      return _i4.ArtistPage(args.artistId, key: args.key);
    },
  );
}

class ArtistRouteArgs {
  const ArtistRouteArgs({required this.artistId, this.key});

  final String artistId;

  final _i49.Key? key;

  @override
  String toString() {
    return 'ArtistRouteArgs{artistId: $artistId, key: $key}';
  }
}

/// generated route for
/// [_i5.BlackListPage]
class BlackListRoute extends _i48.PageRouteInfo<void> {
  const BlackListRoute({List<_i48.PageRouteInfo>? children})
    : super(BlackListRoute.name, initialChildren: children);

  static const String name = 'BlackListRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i5.BlackListPage();
    },
  );
}

/// generated route for
/// [_i6.CatalogPage]
class CatalogRoute extends _i48.PageRouteInfo<void> {
  const CatalogRoute({List<_i48.PageRouteInfo>? children})
    : super(CatalogRoute.name, initialChildren: children);

  static const String name = 'CatalogRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i6.CatalogPage();
    },
  );
}

/// generated route for
/// [_i7.ConnectControlPage]
class ConnectControlRoute extends _i48.PageRouteInfo<void> {
  const ConnectControlRoute({List<_i48.PageRouteInfo>? children})
    : super(ConnectControlRoute.name, initialChildren: children);

  static const String name = 'ConnectControlRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i7.ConnectControlPage();
    },
  );
}

/// generated route for
/// [_i8.ConnectPage]
class ConnectRoute extends _i48.PageRouteInfo<void> {
  const ConnectRoute({List<_i48.PageRouteInfo>? children})
    : super(ConnectRoute.name, initialChildren: children);

  static const String name = 'ConnectRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i8.ConnectPage();
    },
  );
}

/// generated route for
/// [_i9.CreatorsSupportedPage]
class CreatorsSupportedRoute extends _i48.PageRouteInfo<void> {
  const CreatorsSupportedRoute({List<_i48.PageRouteInfo>? children})
    : super(CreatorsSupportedRoute.name, initialChildren: children);

  static const String name = 'CreatorsSupportedRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i9.CreatorsSupportedPage();
    },
  );
}

/// generated route for
/// [_i10.GettingStartedPage]
class GettingStartedRoute extends _i48.PageRouteInfo<void> {
  const GettingStartedRoute({List<_i48.PageRouteInfo>? children})
    : super(GettingStartedRoute.name, initialChildren: children);

  static const String name = 'GettingStartedRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i10.GettingStartedPage();
    },
  );
}

/// generated route for
/// [_i11.HomeBrowseSectionItemsPage]
class HomeBrowseSectionItemsRoute
    extends _i48.PageRouteInfo<HomeBrowseSectionItemsRouteArgs> {
  HomeBrowseSectionItemsRoute({
    _i51.Key? key,
    required String sectionId,
    required _i50.DeeMusiqBrowseSectionObject<Object> section,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         HomeBrowseSectionItemsRoute.name,
         args: HomeBrowseSectionItemsRouteArgs(
           key: key,
           sectionId: sectionId,
           section: section,
         ),
         rawPathParams: {'sectionId': sectionId},
         initialChildren: children,
       );

  static const String name = 'HomeBrowseSectionItemsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeBrowseSectionItemsRouteArgs>();
      return _i11.HomeBrowseSectionItemsPage(
        key: args.key,
        sectionId: args.sectionId,
        section: args.section,
      );
    },
  );
}

class HomeBrowseSectionItemsRouteArgs {
  const HomeBrowseSectionItemsRouteArgs({
    this.key,
    required this.sectionId,
    required this.section,
  });

  final _i51.Key? key;

  final String sectionId;

  final _i50.DeeMusiqBrowseSectionObject<Object> section;

  @override
  String toString() {
    return 'HomeBrowseSectionItemsRouteArgs{key: $key, sectionId: $sectionId, section: $section}';
  }
}

/// generated route for
/// [_i12.HomePage]
class HomeRoute extends _i48.PageRouteInfo<void> {
  const HomeRoute({List<_i48.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i12.HomePage();
    },
  );
}

/// generated route for
/// [_i13.LastFMLoginPage]
class LastFMLoginRoute extends _i48.PageRouteInfo<void> {
  const LastFMLoginRoute({List<_i48.PageRouteInfo>? children})
    : super(LastFMLoginRoute.name, initialChildren: children);

  static const String name = 'LastFMLoginRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i13.LastFMLoginPage();
    },
  );
}

/// generated route for
/// [_i14.LibraryPage]
class LibraryRoute extends _i48.PageRouteInfo<void> {
  const LibraryRoute({List<_i48.PageRouteInfo>? children})
    : super(LibraryRoute.name, initialChildren: children);

  static const String name = 'LibraryRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i14.LibraryPage();
    },
  );
}

/// generated route for
/// [_i15.LikedPlaylistPage]
class LikedPlaylistRoute extends _i48.PageRouteInfo<LikedPlaylistRouteArgs> {
  LikedPlaylistRoute({
    _i49.Key? key,
    required _i50.DeeMusiqSimplePlaylistObject playlist,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         LikedPlaylistRoute.name,
         args: LikedPlaylistRouteArgs(key: key, playlist: playlist),
         initialChildren: children,
       );

  static const String name = 'LikedPlaylistRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LikedPlaylistRouteArgs>();
      return _i15.LikedPlaylistPage(key: args.key, playlist: args.playlist);
    },
  );
}

class LikedPlaylistRouteArgs {
  const LikedPlaylistRouteArgs({this.key, required this.playlist});

  final _i49.Key? key;

  final _i50.DeeMusiqSimplePlaylistObject playlist;

  @override
  String toString() {
    return 'LikedPlaylistRouteArgs{key: $key, playlist: $playlist}';
  }
}

/// generated route for
/// [_i16.LinkedAccountsPage]
class LinkedAccountsRoute extends _i48.PageRouteInfo<void> {
  const LinkedAccountsRoute({List<_i48.PageRouteInfo>? children})
    : super(LinkedAccountsRoute.name, initialChildren: children);

  static const String name = 'LinkedAccountsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i16.LinkedAccountsPage();
    },
  );
}

/// generated route for
/// [_i17.LocalLibraryPage]
class LocalLibraryRoute extends _i48.PageRouteInfo<LocalLibraryRouteArgs> {
  LocalLibraryRoute({
    required String location,
    _i49.Key? key,
    bool isDownloads = false,
    bool isCache = false,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         LocalLibraryRoute.name,
         args: LocalLibraryRouteArgs(
           location: location,
           key: key,
           isDownloads: isDownloads,
           isCache: isCache,
         ),
         initialChildren: children,
       );

  static const String name = 'LocalLibraryRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocalLibraryRouteArgs>();
      return _i17.LocalLibraryPage(
        args.location,
        key: args.key,
        isDownloads: args.isDownloads,
        isCache: args.isCache,
      );
    },
  );
}

class LocalLibraryRouteArgs {
  const LocalLibraryRouteArgs({
    required this.location,
    this.key,
    this.isDownloads = false,
    this.isCache = false,
  });

  final String location;

  final _i49.Key? key;

  final bool isDownloads;

  final bool isCache;

  @override
  String toString() {
    return 'LocalLibraryRouteArgs{location: $location, key: $key, isDownloads: $isDownloads, isCache: $isCache}';
  }
}

/// generated route for
/// [_i18.LogsPage]
class LogsRoute extends _i48.PageRouteInfo<void> {
  const LogsRoute({List<_i48.PageRouteInfo>? children})
    : super(LogsRoute.name, initialChildren: children);

  static const String name = 'LogsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i18.LogsPage();
    },
  );
}

/// generated route for
/// [_i19.LyricsPage]
class LyricsRoute extends _i48.PageRouteInfo<void> {
  const LyricsRoute({List<_i48.PageRouteInfo>? children})
    : super(LyricsRoute.name, initialChildren: children);

  static const String name = 'LyricsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i19.LyricsPage();
    },
  );
}

/// generated route for
/// [_i20.MiniLyricsPage]
class MiniLyricsRoute extends _i48.PageRouteInfo<MiniLyricsRouteArgs> {
  MiniLyricsRoute({
    _i51.Key? key,
    required _i51.Size prevSize,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         MiniLyricsRoute.name,
         args: MiniLyricsRouteArgs(key: key, prevSize: prevSize),
         initialChildren: children,
       );

  static const String name = 'MiniLyricsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MiniLyricsRouteArgs>();
      return _i20.MiniLyricsPage(key: args.key, prevSize: args.prevSize);
    },
  );
}

class MiniLyricsRouteArgs {
  const MiniLyricsRouteArgs({this.key, required this.prevSize});

  final _i51.Key? key;

  final _i51.Size prevSize;

  @override
  String toString() {
    return 'MiniLyricsRouteArgs{key: $key, prevSize: $prevSize}';
  }
}

/// generated route for
/// [_i21.PlayerLyricsPage]
class PlayerLyricsRoute extends _i48.PageRouteInfo<void> {
  const PlayerLyricsRoute({List<_i48.PageRouteInfo>? children})
    : super(PlayerLyricsRoute.name, initialChildren: children);

  static const String name = 'PlayerLyricsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i21.PlayerLyricsPage();
    },
  );
}

/// generated route for
/// [_i22.PlayerQueuePage]
class PlayerQueueRoute extends _i48.PageRouteInfo<void> {
  const PlayerQueueRoute({List<_i48.PageRouteInfo>? children})
    : super(PlayerQueueRoute.name, initialChildren: children);

  static const String name = 'PlayerQueueRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i22.PlayerQueuePage();
    },
  );
}

/// generated route for
/// [_i23.PlayerTrackSourcesPage]
class PlayerTrackSourcesRoute extends _i48.PageRouteInfo<void> {
  const PlayerTrackSourcesRoute({List<_i48.PageRouteInfo>? children})
    : super(PlayerTrackSourcesRoute.name, initialChildren: children);

  static const String name = 'PlayerTrackSourcesRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i23.PlayerTrackSourcesPage();
    },
  );
}

/// generated route for
/// [_i24.PlaylistPage]
class PlaylistRoute extends _i48.PageRouteInfo<PlaylistRouteArgs> {
  PlaylistRoute({
    _i49.Key? key,
    required String id,
    required _i50.DeeMusiqSimplePlaylistObject playlist,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         PlaylistRoute.name,
         args: PlaylistRouteArgs(key: key, id: id, playlist: playlist),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'PlaylistRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PlaylistRouteArgs>();
      return _i24.PlaylistPage(
        key: args.key,
        id: args.id,
        playlist: args.playlist,
      );
    },
  );
}

class PlaylistRouteArgs {
  const PlaylistRouteArgs({this.key, required this.id, required this.playlist});

  final _i49.Key? key;

  final String id;

  final _i50.DeeMusiqSimplePlaylistObject playlist;

  @override
  String toString() {
    return 'PlaylistRouteArgs{key: $key, id: $id, playlist: $playlist}';
  }
}

/// generated route for
/// [_i25.ProfilePage]
class ProfileRoute extends _i48.PageRouteInfo<void> {
  const ProfileRoute({List<_i48.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i25.ProfilePage();
    },
  );
}

/// generated route for
/// [_i26.PushLeaderboardPage]
class PushLeaderboardRoute extends _i48.PageRouteInfo<void> {
  const PushLeaderboardRoute({List<_i48.PageRouteInfo>? children})
    : super(PushLeaderboardRoute.name, initialChildren: children);

  static const String name = 'PushLeaderboardRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i26.PushLeaderboardPage();
    },
  );
}

/// generated route for
/// [_i27.RootAppPage]
class RootAppRoute extends _i48.PageRouteInfo<void> {
  const RootAppRoute({List<_i48.PageRouteInfo>? children})
    : super(RootAppRoute.name, initialChildren: children);

  static const String name = 'RootAppRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i27.RootAppPage();
    },
  );
}

/// generated route for
/// [_i28.SearchPage]
class SearchRoute extends _i48.PageRouteInfo<void> {
  const SearchRoute({List<_i48.PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i28.SearchPage();
    },
  );
}

/// generated route for
/// [_i29.SettingsMetadataProviderFormPage]
class SettingsMetadataProviderFormRoute
    extends _i48.PageRouteInfo<SettingsMetadataProviderFormRouteArgs> {
  SettingsMetadataProviderFormRoute({
    _i51.Key? key,
    required String title,
    required List<_i50.MetadataFormFieldObject> fields,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         SettingsMetadataProviderFormRoute.name,
         args: SettingsMetadataProviderFormRouteArgs(
           key: key,
           title: title,
           fields: fields,
         ),
         initialChildren: children,
       );

  static const String name = 'SettingsMetadataProviderFormRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsMetadataProviderFormRouteArgs>();
      return _i29.SettingsMetadataProviderFormPage(
        key: args.key,
        title: args.title,
        fields: args.fields,
      );
    },
  );
}

class SettingsMetadataProviderFormRouteArgs {
  const SettingsMetadataProviderFormRouteArgs({
    this.key,
    required this.title,
    required this.fields,
  });

  final _i51.Key? key;

  final String title;

  final List<_i50.MetadataFormFieldObject> fields;

  @override
  String toString() {
    return 'SettingsMetadataProviderFormRouteArgs{key: $key, title: $title, fields: $fields}';
  }
}

/// generated route for
/// [_i31.SettingsPage]
class SettingsRoute extends _i48.PageRouteInfo<void> {
  const SettingsRoute({List<_i48.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i31.SettingsPage();
    },
  );
}

/// generated route for
/// [_i32.SettingsScrobblingPage]
class SettingsScrobblingRoute extends _i48.PageRouteInfo<void> {
  const SettingsScrobblingRoute({List<_i48.PageRouteInfo>? children})
    : super(SettingsScrobblingRoute.name, initialChildren: children);

  static const String name = 'SettingsScrobblingRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i32.SettingsScrobblingPage();
    },
  );
}

/// generated route for
/// [_i33.StatsAlbumsPage]
class StatsAlbumsRoute extends _i48.PageRouteInfo<void> {
  const StatsAlbumsRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsAlbumsRoute.name, initialChildren: children);

  static const String name = 'StatsAlbumsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i33.StatsAlbumsPage();
    },
  );
}

/// generated route for
/// [_i34.StatsArtistsPage]
class StatsArtistsRoute extends _i48.PageRouteInfo<void> {
  const StatsArtistsRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsArtistsRoute.name, initialChildren: children);

  static const String name = 'StatsArtistsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i34.StatsArtistsPage();
    },
  );
}

/// generated route for
/// [_i35.StatsMinutesPage]
class StatsMinutesRoute extends _i48.PageRouteInfo<void> {
  const StatsMinutesRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsMinutesRoute.name, initialChildren: children);

  static const String name = 'StatsMinutesRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i35.StatsMinutesPage();
    },
  );
}

/// generated route for
/// [_i36.StatsPage]
class StatsRoute extends _i48.PageRouteInfo<void> {
  const StatsRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsRoute.name, initialChildren: children);

  static const String name = 'StatsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i36.StatsPage();
    },
  );
}

/// generated route for
/// [_i37.StatsPlaylistsPage]
class StatsPlaylistsRoute extends _i48.PageRouteInfo<void> {
  const StatsPlaylistsRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsPlaylistsRoute.name, initialChildren: children);

  static const String name = 'StatsPlaylistsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i37.StatsPlaylistsPage();
    },
  );
}

/// generated route for
/// [_i38.StatsStreamFeesPage]
class StatsStreamFeesRoute extends _i48.PageRouteInfo<void> {
  const StatsStreamFeesRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsStreamFeesRoute.name, initialChildren: children);

  static const String name = 'StatsStreamFeesRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i38.StatsStreamFeesPage();
    },
  );
}

/// generated route for
/// [_i39.StatsStreamsPage]
class StatsStreamsRoute extends _i48.PageRouteInfo<void> {
  const StatsStreamsRoute({List<_i48.PageRouteInfo>? children})
    : super(StatsStreamsRoute.name, initialChildren: children);

  static const String name = 'StatsStreamsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i39.StatsStreamsPage();
    },
  );
}

/// generated route for
/// [_i40.TokenStorePage]
class TokenStoreRoute extends _i48.PageRouteInfo<void> {
  const TokenStoreRoute({List<_i48.PageRouteInfo>? children})
    : super(TokenStoreRoute.name, initialChildren: children);

  static const String name = 'TokenStoreRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i40.TokenStorePage();
    },
  );
}

/// generated route for
/// [_i41.TrackPage]
class TrackRoute extends _i48.PageRouteInfo<TrackRouteArgs> {
  TrackRoute({
    _i51.Key? key,
    required String trackId,
    List<_i48.PageRouteInfo>? children,
  }) : super(
         TrackRoute.name,
         args: TrackRouteArgs(key: key, trackId: trackId),
         rawPathParams: {'id': trackId},
         initialChildren: children,
       );

  static const String name = 'TrackRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TrackRouteArgs>(
        orElse: () => TrackRouteArgs(trackId: pathParams.getString('id')),
      );
      return _i41.TrackPage(key: args.key, trackId: args.trackId);
    },
  );
}

class TrackRouteArgs {
  const TrackRouteArgs({this.key, required this.trackId});

  final _i51.Key? key;

  final String trackId;

  @override
  String toString() {
    return 'TrackRouteArgs{key: $key, trackId: $trackId}';
  }
}

/// generated route for
/// [_i42.UserAlbumsPage]
class UserAlbumsRoute extends _i48.PageRouteInfo<void> {
  const UserAlbumsRoute({List<_i48.PageRouteInfo>? children})
    : super(UserAlbumsRoute.name, initialChildren: children);

  static const String name = 'UserAlbumsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i42.UserAlbumsPage();
    },
  );
}

/// generated route for
/// [_i43.UserArtistsPage]
class UserArtistsRoute extends _i48.PageRouteInfo<void> {
  const UserArtistsRoute({List<_i48.PageRouteInfo>? children})
    : super(UserArtistsRoute.name, initialChildren: children);

  static const String name = 'UserArtistsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i43.UserArtistsPage();
    },
  );
}

/// generated route for
/// [_i44.UserDownloadsPage]
class UserDownloadsRoute extends _i48.PageRouteInfo<void> {
  const UserDownloadsRoute({List<_i48.PageRouteInfo>? children})
    : super(UserDownloadsRoute.name, initialChildren: children);

  static const String name = 'UserDownloadsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i44.UserDownloadsPage();
    },
  );
}

/// generated route for
/// [_i45.UserLocalLibraryPage]
class UserLocalLibraryRoute extends _i48.PageRouteInfo<void> {
  const UserLocalLibraryRoute({List<_i48.PageRouteInfo>? children})
    : super(UserLocalLibraryRoute.name, initialChildren: children);

  static const String name = 'UserLocalLibraryRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i45.UserLocalLibraryPage();
    },
  );
}

/// generated route for
/// [_i46.UserPlaylistsPage]
class UserPlaylistsRoute extends _i48.PageRouteInfo<void> {
  const UserPlaylistsRoute({List<_i48.PageRouteInfo>? children})
    : super(UserPlaylistsRoute.name, initialChildren: children);

  static const String name = 'UserPlaylistsRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i46.UserPlaylistsPage();
    },
  );
}

/// generated route for
/// [_i47.WalletPage]
class WalletRoute extends _i48.PageRouteInfo<void> {
  const WalletRoute({List<_i48.PageRouteInfo>? children})
    : super(WalletRoute.name, initialChildren: children);

  static const String name = 'WalletRoute';

  static _i48.PageInfo page = _i48.PageInfo(
    name,
    builder: (data) {
      return const _i47.WalletPage();
    },
  );
}
