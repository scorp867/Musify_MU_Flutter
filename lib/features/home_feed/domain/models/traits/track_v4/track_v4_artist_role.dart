/// 1:1 replica of Spotify Android's `p199p/f3i0.java` (`Metadata.ArtistWithRole.ArtistRole`).
enum TrackV4ArtistRole {
  artistRoleUnknown(1),
  artistRoleMainArtist(2),
  artistRoleFeaturedArtist(3),
  artistRoleRemixer(4),
  artistRoleActor(5),
  artistRoleComposer(6),
  artistRoleConductor(7),
  artistRoleOrchestra(8);

  final int code;

  const TrackV4ArtistRole(this.code);
}
