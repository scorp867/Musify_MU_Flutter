import 'package:flutter/material.dart';

/// Exact 1:1 Vector paths extracted from Spotify APK drawable resources:
/// - encore_icon_sort_24.xml
/// - encore_icon_delete_24.xml
/// - encore_icon_add_to_queue_24.xml
/// - encore_icon_shuffle_24.xml
/// - encore_icon_repeat_24.xml
/// - encore_icon_repeat_once_24.xml
/// - encore_icon_time_24.xml
/// - encore_icon_queue_badge_24.xml
/// - encore_icon_pause_24.xml
/// - encore_icon_play_24.xml
/// - encore_icon_arrow_left_24.xml
/// - encore_icon_more_android_24.xml
/// - encore_icon_search_24.xml
/// - encore_icon_download_24.xml
/// - encore_icon_downloaded_24.xml
/// - encore_icon_heart_24.xml
/// - encore_icon_heart_active_24.xml
/// - encore_icon_plus_24.xml
/// - encore_icon_plus_alt_24.xml
/// - encore_icon_add_to_playlist_24.xml
/// - encore_icon_share_android_24.xml
/// - encore_icon_edit_24.xml
/// - encore_icon_spotify_logo_24.xml
/// - encore_icon_verified_check_active_24.xml
/// - encore_icon_user_24.xml
/// - encore_icon_group_24.xml
/// - encore_icon_locked_24.xml
/// - encore_icon_track_24.xml
/// - encore_icon_podcasts_24.xml
/// - encore_icon_list_view_24.xml
/// - encore_icon_x_24.xml
/// - encore_icon_album_24.xml
/// - encore_icon_exclamation_circle_24.xml
/// - encore_icon_minus_alt_24.xml
/// - ic_explicit.xml
class SpotifyEncoreIcons {
  SpotifyEncoreIcons._();

  static const String sortPath =
      'M21,8L3,8L3,6h18zM21,18L3,18v-2h18zM3,13h18v-2L3,11z';

  static const String deletePath =
      'M8,4L8,3a3,3 0,0 1,3 -3h2a3,3 0,0 1,3 3v1h6v2h-0.956l-1.878,14.261'
      'A2,2 0,0 1,17.183 22L6.817,22a2,2 0,0 1,-1.983 -1.739L2.956,6L2,6L2,4z'
      'M10,3v1h4L14,3a1,1 0,0 0,-1 -1h-2a1,1 0,0 0,-1 1'
      'M4.974,6l1.843,14h10.366l1.843,-14z';

  static const String addToQueuePath1 =
      'M10.929,5C10.976,4.673 11,4.34 11,4C11,3.66 10.976,3.327 10.929,3H18.55'
      'C20.483,3 22.05,4.567 22.05,6.5C22.05,8.433 20.483,10 18.55,10H7.607'
      'C8.453,9.491 9.182,8.807 9.745,8H18.55C19.378,8 20.05,7.328 20.05,6.5'
      'C20.05,5.672 19.378,5 18.55,5H10.929Z';
  static const String addToQueuePath2 = 'M3,16H21V14H3V16Z';
  static const String addToQueuePath3 = 'M3,22H21V20H3V22Z';
  static const String addToQueuePath4 = 'M5,3H8V5H5V8H3V5H0L0,3H3V0L5,0V3Z';

  static const List<String> addToQueuePaths = [
    addToQueuePath1,
    addToQueuePath2,
    addToQueuePath3,
    addToQueuePath4,
  ];
  static const List<String> deletePaths = [deletePath];

  static const String shufflePath1 =
      'M18.788,3.702a1,1 0,0 1,1.414 -1.414L23.914,6l-3.712,3.712'
      'a1,1 0,1 1,-1.414 -1.414L20.086,7h-1.518a5,5 0,0 0,-3.826 1.78'
      'l-7.346,8.73a7,7 0,0 1,-5.356 2.494H1v-2h1.04a5,5 0,0 0,3.826 -1.781'
      'l7.345,-8.73A7,7 0,0 1,18.569 5h1.518l-1.298,-1.298z';
  static const String shufflePath2 =
      'M18.788,14.289a1,1 0,0 0,0 1.414L20.086,17h-1.518'
      'a5,5 0,0 1,-3.826 -1.78l-1.403,-1.668 -1.306,1.554 1.178,1.4'
      'A7,7 0,0 0,18.568 19h1.518l-1.298,1.298a1,1 0,1 0,1.414 1.414'
      'L23.914,18l-3.712,-3.713a1,1 0,0 0,-1.414 0z'
      'M7.396,6.49l2.023,2.404 -1.307,1.553 -2.246,-2.67'
      'a5,5 0,0 0,-3.826 -1.78H1v-2h1.04A7,7 0,0 1,7.396 6.49';

  static const String repeatPath =
      'M6,2a5,5 0,0 0,-5 5v8a5,5 0,0 0,5 5h1v-2H6a3,3 0,0 1,-3 -3V7'
      'a3,3 0,0 1,3 -3h12a3,3 0,0 1,3 3v8a3,3 0,0 1,-3 3h-4.798'
      'l1.298,-1.298a1,1 0,1 0,-1.414 -1.414L9.373,19l3.713,3.712'
      'a1,1 0,0 0,1.414 -1.414L13.202,20H18a5,5 0,0 0,5 -5V7a5,5 0,0 0,-5 -5z';

  static const String repeatOncePath1 =
      'M1,7a5,5 0,0 1,5 -5h1v2L6,4a3,3 0,0 0,-3 3v8a3,3 0,0 0,3 3h1v2'
      'L6,20a5,5 0,0 1,-5 -5zM18,4h-1L17,2h1a5,5 0,0 1,5 5v8a5,5 0,0 1,-5 5'
      'h-7.202v-2L18,18a3,3 0,0 0,3 -3L21,7a3,3 0,0 0,-3 -3';
  static const String repeatOncePath2 =
      'M14.5,15.288a1,1 0,0 1,0 1.414L12.202,19l2.298,2.298'
      'a1,1 0,0 1,-1.414 1.415L9.373,19l3.713,-3.712a1,1 0,0 1,1.414 0'
      'M11.967,3.202l1.008,0.91H9.559v-1.4q1.316,-0.098 1.918,-0.49'
      'c0.602,-0.392 0.649,-0.649 0.742,-1.162h1.75V11h-2.002z';

  // Sleep Timer stopwatch icon (matching Spotify queue controls dock)
  static const String timePath1 =
      'M9,1a1,1 0,0 0,0 2h6a1,1 0,1 0,0 -2z'
      'M12,4.5a9.25,9.25 0,1 0,0 18.5a9.25,9.25 0,1 0,0 -18.5z'
      'M12,6.5a7.25,7.25 0,1 1,0 14.5a7.25,7.25 0,1 1,0 -14.5z';
  static const String timePath2 =
      'M12,8.5a1,1 0,0 1,1 1v4.25a1,1 0,1 1,-2 0V9.5a1,1 0,0 1,1 -1';

  // Extracted from encore_icon_queue_badge_24.xml
  static const String queueBadgePath1 =
      'M5,6.5A1.5,1.5 0,0 1,6.5 5h11a1.5,1.5 0,0 1,0 3h-11A1.5,1.5 0,0 1,5 6.5';
  static const String queueBadgePath2 =
      'M3,1a2,2 0,0 0,-2 2v18a2,2 0,0 0,2 2h18a2,2 0,0 0,2 -2L23,3a2,2 0,0 0,-2 -2z'
      'M20,15L4,15v-2h16z'
      'M20,20L4,20v-2h16z'
      'M6.5,3h11a3.5,3.5 0,1 1,0 7h-11a3.5,3.5 0,1 1,0 -7'
      'm0,2a1.5,1.5 0,1 0,0 3h11a1.5,1.5 0,0 0,0 -3z';

  // Extracted from encore_icon_pause_24.xml
  static const String pausePath =
      'M5.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6'
      'a0.7,0.7 0,0 0,0.7 -0.7L9,3.7a0.7,0.7 0,0 0,-0.7 -0.7z'
      'M15.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6'
      'a0.7,0.7 0,0 0,0.7 -0.7L19,3.7a0.7,0.7 0,0 0,-0.7 -0.7z';

  // Extracted from encore_icon_play_24.xml
  static const String playPath =
      'm7.05,3.606 l13.49,7.788a0.7,0.7 0,0 1,0 1.212L7.05,20.394'
      'A0.7,0.7 0,0 1,6 19.788V4.212a0.7,0.7 0,0 1,1.05 -0.606';

  static const String checkPath =
      'M1,12.5l7,7L23,4.5l-1.5,-1.5L8,16.5L2.5,11z';

  static const String crossPath =
      'M3.293,3.293a1,1 0,0 1,1.414 0L12,10.586l7.293,-7.293a1,1 0,1 1,1.414 1.414L13.414,12l7.293,7.293a1,1 0,0 1,-1.414 1.414L12,13.414l-7.293,7.293a1,1 0,0 1,-1.414 -1.414L10.586,12 3.293,4.707a1,1 0,0 1,0 -1.414';

  static const String chevronDownPath =
      'M2.793,8.043a1,1 0,0 1,1.414 0L12,15.836l7.793,-7.793a1,1 0,1 1,1.414 1.414L12,18.664 2.793,9.457a1,1 0,0 1,0 -1.414';

  // Extracted from encore_icon_arrow_left_24.xml
  static const String arrowLeftPath =
      'M13.414,3.5a0.999,0.999 0,0 0,-1.707 -0.707l-9.207,9.2 9.207,9.202'
      'a1,1 0,1 0,1.414 -1.413L6.335,13H20.5a1,1 0,0 0,0 -2H6.322l6.799,-6.794'
      'a1,1 0,0 0,0.293 -0.707z';

  // Extracted from encore_icon_more_android_24.xml
  static const String moreAndroidPath =
      'M10.5,4.5a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0'
      'm0,15a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0'
      'm0,-7.5a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0';

  // Extracted from encore_icon_search_24.xml
  static const String searchPath =
      'M10.533,1.279C5.352,1.279 1.126,5.419 1.126,10.558'
      'C1.126,15.697 5.352,19.837 10.533,19.837C12.767,19.837 14.823,19.067 16.44,17.779'
      'L20.793,22.132C21.183,22.523 21.817,22.523 22.207,22.132'
      'C22.598,21.742 22.598,21.108 22.207,20.718L17.863,16.374'
      'C19.162,14.785 19.94,12.763 19.94,10.558C19.94,5.419 15.714,1.279 10.533,1.279Z'
      'M3.126,10.558C3.126,6.552 6.428,3.279 10.533,3.279'
      'C14.638,3.279 17.94,6.552 17.94,10.558C17.94,14.564 14.638,17.837 10.533,17.837'
      'C6.428,17.837 3.126,14.564 3.126,10.558Z';

  // Extracted from encore_icon_download_24.xml
  static const String downloadPath1 =
      'M12,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18'
      'M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12';
  static const String downloadPath2 =
      'M12,6.05a1,1 0,0 1,1 1v7.486l1.793,-1.793a1,1 0,1 1,1.414 1.414'
      'L12,18.364l-4.207,-4.207a1,1 0,1 1,1.414 -1.414L11,14.536V7.05a1,1 0,0 1,1 -1';

  static const List<String> downloadPaths = [
    downloadPath1,
    downloadPath2,
  ];

  // Extracted from encore_icon_downloaded_24.xml
  static const String downloadedPath =
      'M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12'
      'm12,-4.95a1,1 0,0 0,-2 0v7.486l-1.793,-1.793a1,1 0,0 0,-1.414 1.414'
      'L12,18.364l4.207,-4.207a1,1 0,0 0,-1.414 -1.415L13,14.535z';

  // Extracted from encore_icon_heart_24.xml
  static const String heartPath =
      'M5.21,1.57a6.76,6.76 0,0 1,6.708 1.545,0.124 0.124,0 0,0 0.165,0'
      ' 6.74,6.74 0,0 1,5.715 -1.78l0.004,0.001a6.8,6.8 0,0 1,5.571 5.376'
      'v0.003a6.69,6.69 0,0 1,-1.49 5.655l-7.954,9.48a2.518,2.518 0,0 1,-3.857 0'
      'L2.12,12.37A6.68,6.68 0,0 1,0.627 6.714,6.76 6.76,0 0,1 5.21,1.57'
      'm3.12,1.803a4.757,4.757 0,0 0,-5.74 3.725l-0.001,0.002'
      'a4.68,4.68 0,0 0,1.049 3.969l0.009,0.01 7.958,9.485a0.518,0.518 0,0 0,0.79 0'
      'l7.968,-9.495a4.69,4.69 0,0 0,1.049 -3.965,4.8 4.8,0 0,0 -3.931,-3.794'
      ' 4.74,4.74 0,0 0,-4.023 1.256l-0.008,0.008a2.123,2.123 0,0 1,-2.9 0'
      'l-0.007,-0.007a4.76,4.76 0,0 0,-2.214 -1.194z';

  // Extracted from encore_icon_heart_active_24.xml
  static const String heartActivePath =
      'M8.667,1.912a6.257,6.257 0,0 0,-7.462 7.677c0.24,0.906 0.683,1.747 1.295,2.457'
      'l7.955,9.482a2.015,2.015 0,0 0,3.09 0l7.956,-9.482a6.19,6.19 0,0 0,1.382 -5.234'
      'l-0.49,0.097 0.49,-0.099a6.3,6.3 0,0 0,-5.162 -4.98h-0.002a6.24,6.24 0,0 0,-5.295 1.65'
      'a0.623,0.623 0,0 1,-0.848,0 6.26,6.26 0,0 0,-2.91 -1.568z';

  // Extracted from encore_icon_plus_24.xml
  static const String plusPath =
      'M12,1a1,1 0,0 1,1 1v9h9a1,1 0,1 1,0 2h-9v9a1,1 0,1 1,-2 0v-9H2'
      'a1,1 0,1 1,0 -2h9V2a1,1 0,0 1,1 -1';

  // Extracted from encore_icon_plus_alt_24.xml
  static const String plusAltPath1 =
      'M11.999,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18'
      'm-11,9c0,-6.075 4.925,-11 11,-11s11,4.925 11,11 -4.925,11 -11,11 -11,-4.925 -11,-11';
  static const String plusAltPath2 =
      'M17.999,12a1,1 0,0 1,-1 1h-4v4a1,1 0,1 1,-2 0v-4h-4a1,1 0,1 1,0 -2'
      'h4V7a1,1 0,1 1,2 0v4h4a1,1 0,0 1,1 1';

  static const List<String> plusAltPaths = [
    plusAltPath1,
    plusAltPath2,
  ];

  // Extracted from encore_icon_add_to_playlist_24.xml
  static const String addToPlaylistPath =
      'M3,8L3,5L0,5L0,3h3L3,0h2v3h3v2L5,5v3z'
      'M11,4q0,0.51 -0.07,1L19,5v9.667h-1.5a3.5,3.5 0,1 0,3.5 3.5L21,3L10.93,3q0.07,0.49 0.07,1'
      'm8,12.667v1.5a1.5,1.5 0,1 1,-1.5 -1.5z'
      'M6,10.71a7,7 0,0 0,2 -0.965v8.422a3.5,3.5 0,1 1,-3.5 -3.5L6,14.667z'
      'M6,16.667L4.5,16.667a1.5,1.5 0,1 0,1.5 1.5z';

  // Extracted from encore_icon_share_android_24.xml
  static const String shareAndroidPath =
      'M18.5,4a1.5,1.5 0,1 0,0 3,1.5 1.5,0 0,0 0,-3'
      'M15,5.5a3.5,3.5 0,1 1,1.006 2.455L9,12l7.006,4.045'
      'a3.5,3.5 0,1 1,-0.938 1.768l-6.67,-3.85a3.5,3.5 0,1 1,0 -3.924'
      'l6.67,-3.852A3.5,3.5 0,0 1,15 5.5'
      'm-9.5,5a1.5,1.5 0,1 0,0 3,1.5 1.5,0 0,0 0,-3'
      'm13,6.5a1.5,1.5 0,1 0,-0.001 3,1.5 1.5,0 0,0 0.001,-3';

  // Extracted from encore_icon_edit_24.xml
  static const String editPath =
      'M17.318,1.975a3.329,3.329 0,1 1,4.707 4.707L8.451,20.256'
      'c-0.49,0.49 -1.082,0.867 -1.735,1.103L2.34,22.94a1,1 0,0 1,-1.28 -1.28'
      'l1.581,-4.376a4.7,4.7 0,0 1,1.103 -1.735z'
      'M20.611,3.389a1.33,1.33 0,0 0,-1.88 0L5.159,16.963'
      'c-0.283,0.283 -0.5,0.624 -0.636,1l-0.857,2.372 2.371,-0.857'
      'a2.7,2.7 0,0 0,1.001 -0.636L20.611,5.268a1.33,1.33 0,0 0,0 -1.879';

  // Extracted from encore_icon_spotify_logo_24.xml
  static const String spotifyLogoPath =
      'M12.438,1.009C6.368,0.769 1.251,5.494 1.008,11.565'
      'c-0.24,6.07 4.485,11.186 10.556,11.426 6.07,0.242 11.185,-4.484 11.427,-10.554'
      'S18.507,1.251 12.438,1.009'
      'm4.644,16.114a0.657,0.657 0,0 1,-0.897 0.246'
      'a13.2,13.2 0,0 0,-4.71 -1.602 13.2,13.2 0,0 0,-4.968 0.242'
      'a0.658,0.658 0,0 1,-0.31 -1.278 14.5,14.5 0,0 1,5.46 -0.265'
      'c1.837,0.257 3.579,0.851 5.177,1.76 0.315,0.178 0.425,0.58 0.246,0.896z'
      'M18.527,14.236a0.853,0.853 0,0 1,-1.158 0.344'
      'a16.2,16.2 0,0 0,-5.475 -1.797 16.2,16.2 0,0 0,-5.758 0.219'
      'a0.855,0.855 0,0 1,-1.018 -0.65 0.85,0.85 0,0 1,0.65 -1.018'
      'a17.9,17.9 0,0 1,6.362 -0.241 17.9,17.9 0,0 1,6.049 1.985'
      'c0.415,0.224 0.57,0.743 0.344,1.158z'
      'M20.129,10.981a1.05,1.05 0,0 1,-1.418 0.448'
      'a19.7,19.7 0,0 0,-6.341 -2.025 19.6,19.6 0,0 0,-6.655 0.199'
      'a1.05,1.05 0,1 1,-0.417 -2.06 21.7,21.7 0,0 1,7.364 -0.22'
      'a21.7,21.7 0,0 1,7.019 2.24c0.515,0.268 0.715,0.903 0.448,1.418';

  // Extracted from encore_icon_verified_check_active_24.xml
  static const String verifiedCheckPath =
      'M10.814,0.5a1.66,1.66 0,0 1,2.372 0l2.512,2.572 3.595,-0.043'
      'a1.66,1.66 0,0 1,1.678 1.678l-0.043,3.595 2.572,2.512'
      'c0.667,0.65 0.667,1.722 0,2.372l-2.572,2.512 0.043,3.595'
      'a1.66,1.66 0,0 1,-1.678 1.678l-3.595,-0.043 -2.512,2.572'
      'a1.66,1.66 0,0 1,-2.372 0l-2.512,-2.572 -3.595,0.043'
      'a1.66,1.66 0,0 1,-1.678 -1.678l0.043,-3.595L0.5,13.186'
      'a1.66,1.66 0,0 1,0 -2.372l2.572,-2.512 -0.043,-3.595'
      'a1.66,1.66 0,0 1,1.678 -1.678l3.595,0.043z'
      'M17.398,9.62a1,1 0,0 0,-1.414 -1.413l-6.011,6.01 -1.894,-1.893'
      'a1,1 0,0 0,-1.414 1.414l3.308,3.308z';

  // Extracted from encore_icon_user_24.xml
  static const String userPath =
      'M10.165,11.101a2.5,2.5 0,0 1,-0.67 3.766L5.5,17.173'
      'A3,3 0,0 0,4 19.771v0.232h16.001v-0.232a3,3 0,0 0,-1.5 -2.598'
      'l-3.995,-2.306a2.5,2.5 0,0 1,-0.67 -3.766l0.521,-0.626 0.002,-0.002'
      'c0.8,-0.955 1.303,-1.987 1.375,-3.19 0.041,-0.706 -0.088,-1.433 -0.187,-1.727'
      'a3.7,3.7 0,0 0,-0.768 -1.334,3.767 3.767,0 0,0 -5.557,0'
      'c-0.34,0.37 -0.593,0.82 -0.768,1.334 -0.1,0.294 -0.228,1.021 -0.187,1.727'
      ' 0.072,1.203 0.575,2.235 1.375,3.19l0.002,0.002z'
      'M15.892,11.758 L15.372,12.382a0.5,0.5 0,0 0,0.134 0.753'
      'l3.995,2.306a5,5 0,0 1,2.5 4.33v2.232L2,22.003L2,19.77'
      'a5,5 0,0 1,2.5 -4.33l3.995,-2.306a0.5,0.5 0,0 0,0.134 -0.753'
      'l-0.518,-0.622 -0.002,-0.002c-1,-1.192 -1.735,-2.62 -1.838,-4.356'
      ' -0.056,-0.947 0.101,-1.935 0.29,-2.49A5.7,5.7 0,0 1,7.748 2.87'
      'a5.77,5.77 0,0 1,8.505 0,5.7 5.7,0 0,1 1.187,2.043'
      'c0.189,0.554 0.346,1.542 0.29,2.489 -0.103,1.736 -0.838,3.163 -1.837,4.355m-0.001,0.001';

  // Extracted from encore_icon_group_24.xml
  static const String groupPath =
      'M6.112,13.497q-0.021,-0.442 0.013,-0.885h-3.94c0.216,-0.57 0.621,-1.05 1.148,-1.357'
      'l1.4,-0.807a2.337,2.337 0,0 0,0.624 -3.521,2.75 2.75,0 0,1 -0.654,-2.63'
      'A1.85,1.85 0,0 1,5.728 3.16a1.915,1.915 0,0 1,2.182 0.458,1.9 1.9,0 0,1 0.389,0.677'
      ' 2.76,2.76 0,0 1,-0.657 2.633,2.33 2.33,0 0,0 -0.506,1.9q0.051,0.282 0.173,0.544'
      'a4,4 0,0 1,0.33 -0.4,5.9 5.9,0 0,1 1.978,-1.418l0.05,-0.018a4.7,4.7 0,0 0,0.721 -2.215'
      'a4.8,4.8 0,0 0,-0.2 -1.668 3.891,3.891 0,0 0,-7.383 0,4.8 4.8,0 0,0 -0.2,1.671'
      ' 4.9,4.9 0,0 0,1.21 2.887,0.335 0.335,0 0,1 -0.09,0.506l-1.399,0.807'
      'A4.72,4.72 0,0 0,-0.007 13.61v1L6.27,14.61a6.6,6.6 0,0 1,-0.158 -1.114z'
      'M21.661,9.523 L20.261,8.715a0.33,0.33 0,0 1,-0.162 -0.231,0.33 0.33,0 0,1 0.072,-0.273'
      ' 4.9,4.9 0,0 0,1.212 -2.889,4.8 4.8,0 0,0 -0.2,-1.668 3.89,3.89 0,0 0,-5.967 -1.929'
      'A3.9,3.9 0,0 0,13.8 3.654a4.8,4.8 0,0 0,-0.2 1.671c0.05,0.787 0.3,1.549 0.723,2.214'
      'l0.048,0.018c0.75,0.33 1.423,0.813 1.977,1.418 0.12,0.13 0.227,0.268 0.331,0.4'
      'a2.3,2.3 0,0 0,-0.334 -2.451,2.75 2.75,0 0,1 -0.655,-2.63 1.85,1.85 0,0 1,1.028 -1.136'
      ' 1.91,1.91 0,0 1,2.18,0.458 1.9,1.9 0,0 1,0.388 0.677,2.76 2.76,0 0,1 -0.656,2.633'
      ' 2.337,2.337 0,0 0,0.624 3.519l1.4,0.808c0.53,0.308 0.938,0.789 1.155,1.362'
      'h-3.942q0.035,0.442 0.014,0.885a6.5,6.5 0,0 1,-0.165 1.115h6.277v-1'
      'a4.72,4.72 0,0 0,-2.332 -4.092m-5.499,8.056 l-1.4,-0.808'
      'a0.33,0.33 0,0 1,-0.156 -0.376,0.3 0.3,0 0,1 0.067,-0.128 4.9,4.9 0,0 0,1.211 -2.89'
      'a4.8,4.8 0,0 0,-0.2 -1.668 3.891,3.891 0,0 0,-7.382 0,4.8 4.8,0 0,0 -0.2,1.671'
      ' 4.9,4.9 0,0 0,1.21 2.887,0.334 0.334,0 0,1 -0.09,0.506l-1.4,0.808'
      'a4.72,4.72 0,0 0,-2.333 4.088v1h12.997v-1a4.72,4.72 0,0 0,-2.324 -4.09'
      'm-8.48,3.088a2.67,2.67 0,0 1,1.15 -1.356l1.399,-0.808a2.334,2.334 0,0 0,0.625 -3.52'
      'a2.75,2.75 0,0 1 -0.655,-2.63 1.86,1.86 0,0 1,1.028 -1.136 1.93,1.93 0,0 1,1.54,0'
      ' 1.85,1.85 0,0 1,1.028 1.135c0.079,0.296 0.11,0.602 0.094,0.908'
      'a2.9,2.9 0,0 1,-0.75 1.725,2.335,2.335 0,0 0,0.624,3.518l1.4,0.808'
      'c0.526,0.308 0.93,0.786 1.147,1.356z';

  // Extracted from encore_icon_locked_24.xml
  static const String lockedPath =
      'M6,7a6,6 0,1 1,12 0v3h1a2,2 0,0 1,2 2v8a2,2 0,0 1,-2 2L5,22'
      'a2,2 0,0 1,-2 -2v-8a2,2 0,0 1,2 -2h1zM8,10h8L16,7a4,4 0,0 0,-8 0zM5,12v8h14v-8z';

  // Extracted from encore_icon_track_24.xml
  static const String trackPath =
      'M15,4v12.167a3.5,3.5 0,1 1,-3.5 -3.5L13,12.667L13,4z'
      'M13,14.667h-1.5a1.5,1.5 0,1 0,1.5 1.5z';

  // Extracted from encore_icon_podcasts_24.xml
  static const String podcastsPath1 =
      'M12,3a9,9 0,0 0,-7.046 14.6L3.42,18.886A10.95,10.95 0,0 1,1 12'
      'C1,5.925 5.925,1 12,1s11,4.925 11,11a10.96,10.96 0,0 1,-2.421 6.886L19.046,17.6'
      'A9,9 0,0 0,12 3';
  static const String podcastsPath2 =
      'M12,7a4,4 0,0 0,-4 4v3a4,4 0,0 0,3 3.874v1.965l-2.715,2.278'
      'a0.5,0.5 0,0 0,0.322 0.883h6.786a0.5,0.5 0,0 0,0.322 -0.883L13,19.839'
      'v-1.965c1.725,-0.444 3,-2.01 3,-3.874v-3a4,4 0,0 0,-4 -4m2,7a2,2 0,0 1,-4 0v-3a2,2 0,1 1,4 0z';

  static const List<String> podcastsPaths = [
    podcastsPath1,
    podcastsPath2,
  ];

  // Extracted from encore_icon_list_view_24.xml
  static const String listViewPath =
      'M22,5L8,5L8,3h14zM22,21L8,21v-2h14zM22,13L8,13v-2h14z'
      'M5,4a1.5,1.5 0,1 1,-3 0,1.5 1.5,0 0,1 3,0'
      'm0,8a1.5,1.5 0,1 1,-3 0,1.5 1.5,0 0,1 3,0'
      'm0,8a1.5,1.5 0,1 1,-3 0,1.5 1.5,0 0,1 3,0';

  // Extracted from encore_icon_album_24.xml
  static const String albumPath1 =
      'M12,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18'
      'M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12';
  static const String albumPath2 =
      'M12,10a2,2 0,1 0,0 4,2 2,0 0,0 0,-4m-4,2a4,4 0,1 1,8 0,4 4,0 0,1 -8,0';

  static const List<String> albumPaths = [
    albumPath1,
    albumPath2,
  ];

  // Extracted from encore_icon_exclamation_circle_24.xml
  static const String exclamationCirclePath1 =
      'M11,18v-2h2v2zM11,14L11,6h2v8z';
  static const String exclamationCirclePath2 =
      'M12,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18'
      'M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12';

  static const List<String> exclamationCirclePaths = [
    exclamationCirclePath1,
    exclamationCirclePath2,
  ];

  // Extracted from encore_icon_minus_alt_24.xml
  static const String minusAltPath1 =
      'M16.999,11h-10v2h10z';
  static const String minusAltPath2 =
      'M11.999,1c-6.075,0 -11,4.925 -11,11s4.925,11 11,11 11,-4.925 11,-11 -4.925,-11 -11,-11'
      'm-9,11a9,9 0,1 1,18 0,9 9,0 0,1 -18,0';

  static const List<String> minusAltPaths = [
    minusAltPath1,
    minusAltPath2,
  ];

  // Extracted from ic_explicit.xml (viewport 32x32)
  static const String explicitPath =
      'M4,0C1.791,0 0,1.791 0,4V28C0,30.209 1.791,32 4,32H28C30.209,32 32,30.209 32,28'
      'V4C32,1.791 30.209,0 28,0H4Z'
      'M22.222,22.192V25.778H10.667V6.222H22.222V9.808H14.258V14.276H21.467V17.669H14.258V22.192H22.222Z';
}

/// Widget that renders any extracted Spotify Encore SVG Path accurately.
class SpotifyIcon extends StatelessWidget {
  final List<String> paths;
  final Color color;
  final double size;
  final double viewportSize;

  const SpotifyIcon({
    super.key,
    required this.paths,
    this.color = Colors.white,
    this.size = 24.0,
    this.viewportSize = 24.0,
  });

  factory SpotifyIcon.sort({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.sortPath], color: color, size: size);

  factory SpotifyIcon.delete({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.deletePath], color: color, size: size);

  factory SpotifyIcon.addToQueue({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        key: key,
        paths: SpotifyEncoreIcons.addToQueuePaths,
        color: color,
        size: size,
      );

  factory SpotifyIcon.shuffle({
    Key? key,
    Color color = Colors.white,
    double size = 24,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [
          SpotifyEncoreIcons.shufflePath1,
          SpotifyEncoreIcons.shufflePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.repeat({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.repeatPath], color: color, size: size);

  factory SpotifyIcon.repeatOnce({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        key: key,
        paths: const [
          SpotifyEncoreIcons.repeatOncePath1,
          SpotifyEncoreIcons.repeatOncePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.timer({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        key: key,
        paths: const [
          SpotifyEncoreIcons.timePath1,
          SpotifyEncoreIcons.timePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.queueBadge({Key? key, Color color = Colors.white, double size = 14}) =>
      SpotifyIcon(
        key: key,
        paths: const [
          SpotifyEncoreIcons.queueBadgePath1,
          SpotifyEncoreIcons.queueBadgePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.pause({
    Key? key,
    Color color = Colors.black,
    double size = 16,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.pausePath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.play({
    Key? key,
    Color color = Colors.black,
    double size = 16,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.playPath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.check({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.checkPath], color: color, size: size);

  factory SpotifyIcon.cross({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.crossPath], color: color, size: size);

  factory SpotifyIcon.clear({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.crossPath], color: color, size: size);

  factory SpotifyIcon.chevronDown({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.chevronDownPath], color: color, size: size);

  factory SpotifyIcon.arrowLeft({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.arrowLeftPath], color: color, size: size);

  factory SpotifyIcon.back({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.arrowLeftPath], color: color, size: size);

  factory SpotifyIcon.more({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.moreAndroidPath], color: color, size: size);

  factory SpotifyIcon.search({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.searchPath], color: color, size: size);

  factory SpotifyIcon.download({
    Key? key,
    Color color = Colors.white,
    double size = 24,
  }) =>
      SpotifyIcon(
        key: key,
        paths: SpotifyEncoreIcons.downloadPaths,
        color: color,
        size: size,
      );

  factory SpotifyIcon.downloaded({
    Key? key,
    Color color = const Color(0xFF1DB954),
    double size = 24,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.downloadedPath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.heart({
    Key? key,
    Color color = Colors.white,
    double size = 24,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.heartPath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.heartActive({
    Key? key,
    Color color = const Color(0xFF1DB954),
    double size = 24,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.heartActivePath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.plus({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.plusPath], color: color, size: size);

  factory SpotifyIcon.plusCircle({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        key: key,
        paths: SpotifyEncoreIcons.plusAltPaths,
        color: color,
        size: size,
      );

  factory SpotifyIcon.addToPlaylist({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.addToPlaylistPath], color: color, size: size);

  factory SpotifyIcon.share({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.shareAndroidPath], color: color, size: size);

  factory SpotifyIcon.edit({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.editPath], color: color, size: size);

  factory SpotifyIcon.spotifyLogo({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.spotifyLogoPath], color: color, size: size);

  factory SpotifyIcon.verifiedCheck({Key? key, Color color = const Color(0xFF1DB954), double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.verifiedCheckPath], color: color, size: size);

  factory SpotifyIcon.user({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.userPath], color: color, size: size);

  factory SpotifyIcon.group({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.groupPath], color: color, size: size);

  factory SpotifyIcon.locked({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.lockedPath], color: color, size: size);

  factory SpotifyIcon.track({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.trackPath], color: color, size: size);

  factory SpotifyIcon.podcasts({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        key: key,
        paths: SpotifyEncoreIcons.podcastsPaths,
        color: color,
        size: size,
      );

  factory SpotifyIcon.listView({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: const [SpotifyEncoreIcons.listViewPath], color: color, size: size);

  factory SpotifyIcon.album({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: SpotifyEncoreIcons.albumPaths, color: color, size: size);

  factory SpotifyIcon.error({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: SpotifyEncoreIcons.exclamationCirclePaths, color: color, size: size);

  factory SpotifyIcon.minusCircle({Key? key, Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(key: key, paths: SpotifyEncoreIcons.minusAltPaths, color: color, size: size);

  factory SpotifyIcon.explicit({
    Key? key,
    Color color = const Color(0xFFB3B3B3),
    double size = 12,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.explicitPath],
        color: color,
        size: size,
        viewportSize: 32.0,
      );

  /// Paints cached Encore vector paths centered at [center] directly onto [canvas]
  /// with zero widget allocations (used by ItemTouchHelper swipe background).
  static void paintIcon(
    Canvas canvas,
    List<String> paths, {
    required Offset center,
    double size = 24.0,
    double viewportSize = 24.0,
    Color color = Colors.white,
  }) {
    final scale = size / viewportSize;
    final topLeft = Offset(center.dx - size * 0.5, center.dy - size * 0.5);
    canvas.save();
    canvas.translate(topLeft.dx, topLeft.dy);
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final pathData in paths) {
      canvas.drawPath(_SvgPathPainter.parseSvgPath(pathData), paint);
    }

    canvas.restore();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SvgPathPainter(
          paths: paths,
          color: color,
          viewportSize: viewportSize,
        ),
      ),
    );
  }
}

class _SvgPathPainter extends CustomPainter {
  final List<String> paths;
  final Color color;
  final double viewportSize;

  const _SvgPathPainter({
    required this.paths,
    required this.color,
    this.viewportSize = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewportSize;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final pathData in paths) {
      final path = parseSvgPath(pathData);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SvgPathPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.paths != paths ||
        oldDelegate.viewportSize != viewportSize;
  }

  static final Map<String, Path> _cache = {};

  static Path parseSvgPath(String d) {
    if (_cache.containsKey(d)) return _cache[d]!;
    final path = _SvgPathParser(d).parse();
    _cache[d] = path;
    return path;
  }
}

/// Complete parser for Android Vector Drawable pathData format
class _SvgPathParser {
  final String d;
  int _index = 0;

  _SvgPathParser(this.d);

  Path parse() {
    final path = Path()..fillType = PathFillType.evenOdd;
    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    double lastControlX = 0;
    double lastControlY = 0;
    String lastCmd = '';
    String prevCmd = '';

    while (_index < d.length) {
      _skipWhitespaceAndCommas();
      if (_index >= d.length) break;

      final char = d[_index];
      if (_isCommand(char)) {
        lastCmd = char;
        _index++;
      }

      switch (lastCmd) {
        case 'M':
          final x = _readDouble();
          final y = _readDouble();
          path.moveTo(x, y);
          currentX = x;
          currentY = y;
          startX = x;
          startY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = 'M';
          lastCmd = 'L';
          break;
        case 'm':
          final dx = _readDouble();
          final dy = _readDouble();
          currentX += dx;
          currentY += dy;
          path.moveTo(currentX, currentY);
          startX = currentX;
          startY = currentY;
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'm';
          lastCmd = 'l';
          break;
        case 'L':
          final x = _readDouble();
          final y = _readDouble();
          path.lineTo(x, y);
          currentX = x;
          currentY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = 'L';
          break;
        case 'l':
          final dx = _readDouble();
          final dy = _readDouble();
          currentX += dx;
          currentY += dy;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'l';
          break;
        case 'H':
          final x = _readDouble();
          path.lineTo(x, currentY);
          currentX = x;
          lastControlX = x;
          lastControlY = currentY;
          prevCmd = 'H';
          break;
        case 'h':
          final dx = _readDouble();
          currentX += dx;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'h';
          break;
        case 'V':
          final y = _readDouble();
          path.lineTo(currentX, y);
          currentY = y;
          lastControlX = currentX;
          lastControlY = y;
          prevCmd = 'V';
          break;
        case 'v':
          final dy = _readDouble();
          currentY += dy;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'v';
          break;
        case 'C':
          final x1 = _readDouble();
          final y1 = _readDouble();
          final x2 = _readDouble();
          final y2 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 'C';
          break;
        case 'c':
          final dx1 = _readDouble();
          final dy1 = _readDouble();
          final dx2 = _readDouble();
          final dy2 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          path.cubicTo(
            currentX + dx1,
            currentY + dy1,
            x2,
            y2,
            currentX + dx,
            currentY + dy,
          );
          lastControlX = x2;
          lastControlY = y2;
          currentX += dx;
          currentY += dy;
          prevCmd = 'c';
          break;
        case 'S':
          final x1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentY - lastControlY
              : currentY;
          final x2 = _readDouble();
          final y2 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 'S';
          break;
        case 's':
          final x1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentY - lastControlY
              : currentY;
          final dx2 = _readDouble();
          final dy2 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          path.cubicTo(x1, y1, x2, y2, currentX + dx, currentY + dy);
          lastControlX = x2;
          lastControlY = y2;
          currentX += dx;
          currentY += dy;
          prevCmd = 's';
          break;
        case 'Q':
          final x1 = _readDouble();
          final y1 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          currentX = x;
          currentY = y;
          prevCmd = 'Q';
          break;
        case 'q':
          final dx1 = _readDouble();
          final dy1 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x1 = currentX + dx1;
          final y1 = currentY + dy1;
          path.quadraticBezierTo(x1, y1, currentX + dx, currentY + dy);
          lastControlX = x1;
          lastControlY = y1;
          currentX += dx;
          currentY += dy;
          prevCmd = 'q';
          break;
        case 'A':
        case 'a':
          final rx = _readDouble();
          final ry = _readDouble();
          final angle = _readDouble();
          final largeArc = _readDouble() != 0;
          final sweep = _readDouble() != 0;
          var x = _readDouble();
          var y = _readDouble();
          if (lastCmd == 'a') {
            x += currentX;
            y += currentY;
          }
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: angle,
            largeArc: largeArc,
            clockwise: sweep,
          );
          currentX = x;
          currentY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = lastCmd;
          break;
        case 'Z':
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          lastControlX = startX;
          lastControlY = startY;
          prevCmd = 'z';
          break;
        default:
          _index++;
          break;
      }
    }
    return path;
  }

  void _skipWhitespaceAndCommas() {
    while (_index < d.length &&
        (d[_index] == ' ' ||
            d[_index] == ',' ||
            d[_index] == '\n' ||
            d[_index] == '\r' ||
            d[_index] == '\t')) {
      _index++;
    }
  }

  bool _isCommand(String char) {
    return 'MLHVCSQTAZmlhvcsqtaz'.contains(char);
  }

  double _readDouble() {
    _skipWhitespaceAndCommas();
    if (_index >= d.length) return 0;
    final start = _index;
    if (d[_index] == '-' || d[_index] == '+') {
      _index++;
    }
    var hasDot = false;
    while (_index < d.length) {
      final c = d[_index];
      if (c == '.') {
        if (hasDot) break;
        hasDot = true;
        _index++;
      } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        _index++;
      } else {
        break;
      }
    }
    final str = d.substring(start, _index);
    return double.tryParse(str) ?? 0;
  }
}
