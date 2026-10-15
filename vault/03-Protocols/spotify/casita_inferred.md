---
title: "casita_inferred.proto"
path: "protos/spotify/casita_inferred.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto2"
package: "spotify.casita"
messages: 119
---

# casita_inferred.proto

> Source Schema: `[protos/spotify/casita_inferred.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/casita_inferred.proto)`
> Syntax: `proto2` | Package: `spotify.casita`

## Schema Overview
`casita_inferred.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Message Definitions
### `message Greeting`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `transformedLabel` |
| `2` | `optional` | `string` | `translatedBaseText` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `height` |
| `2` | `optional` | `string` | `url` |
| `3` | `optional` | `int64` | `width` |

### `message CoverArt`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Publisher`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message Profile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `height` |
| `2` | `optional` | `string` | `url` |
| `3` | `optional` | `int64` | `width` |

### `message AvatarImage`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Visuals`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `AvatarImage` | `avatarImage` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `CoverArt` | `coverArt` |
| `3` | `optional` | `string` | `mediaType` |
| `4` | `optional` | `string` | `name` |
| `5` | `optional` | `Publisher` | `publisher` |
| `6` | `optional` | `string` | `uri` |
| `7` | `optional` | `Profile` | `profile` |
| `8` | `optional` | `Visuals` | `visuals` |

### `message HeaderEntity`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `string` | `_uri` |
| `3` | `optional` | `Data` | `data` |

### `message Subtitle`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `transformedLabel` |
| `2` | `optional` | `string` | `translatedBaseText` |

### `message Title`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `transformedLabel` |
| `2` | `optional` | `string` | `translatedBaseText` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `HeaderEntity` | `headerEntity` |
| `3` | `optional` | `Subtitle` | `subtitle` |
| `4` | `optional` | `Title` | `title` |
| `5` | `optional` | `string` | `iconName` |

### `message Content`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `int64` | `totalCount` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `url` |
| `2` | `optional` | `int64` | `height` |
| `3` | `optional` | `int64` | `width` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Images`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `string` | `name` |
| `3` | `optional` | `string` | `uri` |

### `message OwnerV2`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Data` | `data` |

### `message Attributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `key` |
| `2` | `optional` | `string` | `value` |

### `message Profile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Profile` | `profile` |
| `2` | `optional` | `string` | `uri` |

### `message Artists`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `height` |
| `2` | `optional` | `string` | `url` |
| `3` | `optional` | `int64` | `width` |

### `message CoverArt`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Playability`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `playable` |
| `2` | `optional` | `string` | `reason` |

### `message Profile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `height` |
| `2` | `optional` | `string` | `url` |
| `3` | `optional` | `int64` | `width` |

### `message AvatarImage`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Visuals`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `AvatarImage` | `avatarImage` |

### `message Publisher`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message Duration`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `nanoSeconds` |
| `2` | `optional` | `int64` | `seconds` |

### `message ConsumptionExperienceTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `Duration` | `duration` |

### `message EntityTypeTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `string` | `type` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `uri` |

### `message Contributors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |
| `2` | `optional` | `int64` | `totalCount` |

### `message IdentityTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `Contributors` | `contributors` |
| `3` | `optional` | `string` | `description` |
| `4` | `optional` | `string` | `name` |
| `5` | `optional` | `string` | `type` |

### `message SharingInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `shareId` |
| `2` | `optional` | `string` | `shareUrl` |

### `message TypedEntity`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `imageFormat` |
| `2` | `optional` | `int64` | `maxHeight` |
| `3` | `optional` | `int64` | `maxWidth` |
| `4` | `optional` | `string` | `url` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Image`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Data` | `data` |

### `message FlatFile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `cdnUrl` |

### `message OriginalInstances`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `FlatFile` | `flatFile` |
| `2` | `optional` | `string` | `size` |

### `message SquareCoverImage`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Image` | `image` |
| `2` | `repeated` | `OriginalInstances` | `originalInstances` |

### `message VisualIdentityTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `SquareCoverImage` | `squareCoverImage` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `ConsumptionExperienceTrait` | `consumptionExperienceTrait` |
| `3` | `optional` | `EntityTypeTrait` | `entityTypeTrait` |
| `4` | `optional` | `IdentityTrait` | `identityTrait` |
| `5` | `optional` | `SharingInfo` | `sharingInfo` |
| `6` | `optional` | `TypedEntity` | `typedEntity` |
| `7` | `optional` | `string` | `uri` |
| `8` | `optional` | `VisualIdentityTrait` | `visualIdentityTrait` |

### `message Entity`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `string` | `_uri` |
| `3` | `optional` | `Data` | `data` |

### `message FormatListAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `key` |
| `2` | `optional` | `string` | `value` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Entity` | `entity` |
| `2` | `repeated` | `FormatListAttributes` | `formatListAttributes` |
| `3` | `optional` | `string` | `uid` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |
| `2` | `optional` | `int64` | `totalCount` |

### `message ContentRating`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `label` |

### `message Duration`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `totalMilliseconds` |

### `message PlayedState`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `playPositionMilliseconds` |
| `2` | `optional` | `string` | `state` |

### `message ColorDark`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `hex` |
| `2` | `optional` | `bool` | `isFallback` |

### `message ExtractedColors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorDark` | `colorDark` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `height` |
| `2` | `optional` | `string` | `url` |
| `3` | `optional` | `int64` | `width` |

### `message CoverArt`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtractedColors` | `extractedColors` |
| `2` | `repeated` | `Sources` | `sources` |

### `message Publisher`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message ContentRatingV2`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `string` | `labels` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `CoverArt` | `coverArt` |
| `3` | `optional` | `string` | `mediaType` |
| `4` | `optional` | `string` | `name` |
| `5` | `optional` | `Publisher` | `publisher` |
| `6` | `optional` | `string` | `uri` |
| `7` | `optional` | `ContentRatingV2` | `contentRatingV2` |

### `message PodcastV2`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `Data` | `data` |

### `message ReleaseDate`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `isoString` |
| `2` | `optional` | `string` | `precision` |

### `message Restrictions`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `paywallContent` |

### `message Sources`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `imageFormat` |
| `2` | `optional` | `int64` | `maxHeight` |
| `3` | `optional` | `int64` | `maxWidth` |
| `4` | `optional` | `string` | `url` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `repeated` | `Sources` | `sources` |

### `message ImagePreview`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Data` | `data` |

### `message VideoPreviewThumbnail`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `ImagePreview` | `imagePreview` |

### `message EncoreBaseSetTextColor`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message BackgroundBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message BackgroundTintedBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBrightAccent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextSubdued`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message HighContrast`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BackgroundBase` | `backgroundBase` |
| `2` | `optional` | `BackgroundTintedBase` | `backgroundTintedBase` |
| `3` | `optional` | `TextBase` | `textBase` |
| `4` | `optional` | `TextBrightAccent` | `textBrightAccent` |
| `5` | `optional` | `TextSubdued` | `textSubdued` |

### `message BackgroundBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message BackgroundTintedBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBrightAccent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextSubdued`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message HigherContrast`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BackgroundBase` | `backgroundBase` |
| `2` | `optional` | `BackgroundTintedBase` | `backgroundTintedBase` |
| `3` | `optional` | `TextBase` | `textBase` |
| `4` | `optional` | `TextBrightAccent` | `textBrightAccent` |
| `5` | `optional` | `TextSubdued` | `textSubdued` |

### `message BackgroundBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message BackgroundTintedBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextBrightAccent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message TextSubdued`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `alpha` |
| `2` | `optional` | `int64` | `blue` |
| `3` | `optional` | `int64` | `green` |
| `4` | `optional` | `int64` | `red` |

### `message MinContrast`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BackgroundBase` | `backgroundBase` |
| `2` | `optional` | `BackgroundTintedBase` | `backgroundTintedBase` |
| `3` | `optional` | `TextBase` | `textBase` |
| `4` | `optional` | `TextBrightAccent` | `textBrightAccent` |
| `5` | `optional` | `TextSubdued` | `textSubdued` |

### `message ExtractedColorSet`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EncoreBaseSetTextColor` | `encoreBaseSetTextColor` |
| `2` | `optional` | `HighContrast` | `highContrast` |
| `3` | `optional` | `HigherContrast` | `higherContrast` |
| `4` | `optional` | `MinContrast` | `minContrast` |

### `message SquareCoverImage`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `ExtractedColorSet` | `extractedColorSet` |

### `message VisualIdentity`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SquareCoverImage` | `squareCoverImage` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `Content` | `content` |
| `3` | `optional` | `string` | `description` |
| `4` | `optional` | `string` | `format` |
| `5` | `optional` | `Images` | `images` |
| `6` | `optional` | `string` | `name` |
| `7` | `optional` | `OwnerV2` | `ownerV2` |
| `8` | `optional` | `string` | `uri` |
| `9` | `repeated` | `Attributes` | `attributes` |
| `10` | `optional` | `Artists` | `artists` |
| `11` | `optional` | `CoverArt` | `coverArt` |
| `12` | `optional` | `bool` | `isPreRelease` |
| `13` | `optional` | `Playability` | `playability` |
| `14` | `optional` | `string` | `albumType` |
| `15` | `optional` | `Profile` | `profile` |
| `16` | `optional` | `Visuals` | `visuals` |
| `17` | `optional` | `string` | `mediaType` |
| `18` | `optional` | `Publisher` | `publisher` |
| `19` | `optional` | `Items` | `items` |
| `20` | `optional` | `ContentRating` | `contentRating` |
| `21` | `optional` | `Duration` | `duration` |
| `22` | `optional` | `string` | `id` |
| `23` | `repeated` | `string` | `mediaTypes` |
| `24` | `optional` | `PlayedState` | `playedState` |
| `25` | `optional` | `PodcastV2` | `podcastV2` |
| `26` | `optional` | `ReleaseDate` | `releaseDate` |
| `27` | `optional` | `Restrictions` | `restrictions` |
| `28` | `optional` | `string` | `type` |
| `29` | `optional` | `VideoPreviewThumbnail` | `videoPreviewThumbnail` |
| `30` | `optional` | `VisualIdentity` | `visualIdentity` |

### `message Content`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `string` | `uri` |
| `3` | `optional` | `Data` | `data` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Content` | `content` |
| `2` | `optional` | `string` | `uri` |
| `3` | `optional` | `Data` | `data` |

### `message PagingInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `nextOffset` |

### `message SectionItems`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |
| `2` | `optional` | `PagingInfo` | `pagingInfo` |
| `3` | `optional` | `int64` | `totalCount` |

### `message Items`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Data` | `data` |
| `2` | `optional` | `SectionItems` | `sectionItems` |
| `3` | `optional` | `string` | `uri` |

### `message Sections`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Items` | `items` |
| `2` | `optional` | `int64` | `totalCount` |

### `message SectionContainer`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Sections` | `sections` |
| `2` | `optional` | `string` | `uri` |

### `message Label`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `transformedLabel` |
| `2` | `optional` | `string` | `translatedBaseText` |

### `message Label`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `transformedLabel` |
| `2` | `optional` | `string` | `translatedBaseText` |

### `message SubChips`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `id` |
| `2` | `optional` | `Label` | `label` |

### `message HomeChips`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `id` |
| `2` | `optional` | `Label` | `label` |
| `3` | `repeated` | `SubChips` | `subChips` |

### `message Home`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `__typename` |
| `2` | `optional` | `Greeting` | `greeting` |
| `3` | `optional` | `SectionContainer` | `sectionContainer` |
| `4` | `repeated` | `HomeChips` | `homeChips` |

### `message Data`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Home` | `home` |

### `message HomePath`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `continuum` |

### `message ResponseIds`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `HomePath` | `home_path` |

### `message Extensions`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ResponseIds` | `responseIds` |

### `message CasitaResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Data` | `data` |
| `2` | `optional` | `Extensions` | `extensions` |

## Raw Protobuf Definition
```protobuf
syntax = "proto2";

package spotify.casita;

      message Greeting {
        optional string transformedLabel = 1;
        optional string translatedBaseText = 2;
      }

                      message ColorDark {
                        optional string hex = 1;
                        optional bool isFallback = 2;
                      }

                    message ExtractedColors {
                      optional ColorDark colorDark = 1;
                    }

                    message Sources {
                      optional int64 height = 1;
                      optional string url = 2;
                      optional int64 width = 3;
                    }

                  message CoverArt {
                    optional ExtractedColors extractedColors = 1;
                    repeated Sources sources = 2;
                  }

                  message Publisher {
                    optional string name = 1;
                  }

                  message Profile {
                    optional string name = 1;
                  }

                        message ColorDark {
                          optional string hex = 1;
                          optional bool isFallback = 2;
                        }

                      message ExtractedColors {
                        optional ColorDark colorDark = 1;
                      }

                      message Sources {
                        optional int64 height = 1;
                        optional string url = 2;
                        optional int64 width = 3;
                      }

                    message AvatarImage {
                      optional ExtractedColors extractedColors = 1;
                      repeated Sources sources = 2;
                    }

                  message Visuals {
                    optional AvatarImage avatarImage = 1;
                  }

                message Data {
                  optional string __typename = 1;
                  optional CoverArt coverArt = 2;
                  optional string mediaType = 3;
                  optional string name = 4;
                  optional Publisher publisher = 5;
                  optional string uri = 6;
                  optional Profile profile = 7;
                  optional Visuals visuals = 8;
                }

              message HeaderEntity {
                optional string __typename = 1;
                optional string _uri = 2;
                optional Data data = 3;
              }

              message Subtitle {
                optional string transformedLabel = 1;
                optional string translatedBaseText = 2;
              }

              message Title {
                optional string transformedLabel = 1;
                optional string translatedBaseText = 2;
              }

            message Data {
              optional string __typename = 1;
              optional HeaderEntity headerEntity = 2;
              optional Subtitle subtitle = 3;
              optional Title title = 4;
              optional string iconName = 5;
            }

                    message Content {
                      optional string __typename = 1;
                      optional int64 totalCount = 2;
                    }

                          message ColorDark {
                            optional string hex = 1;
                            optional bool isFallback = 2;
                          }

                        message ExtractedColors {
                          optional ColorDark colorDark = 1;
                        }

                        message Sources {
                          optional string url = 1;
                          optional int64 height = 2;
                          optional int64 width = 3;
                        }

                      message Items {
                        optional ExtractedColors extractedColors = 1;
                        repeated Sources sources = 2;
                      }

                    message Images {
                      repeated Items items = 1;
                    }

                      message Data {
                        optional string __typename = 1;
                        optional string name = 2;
                        optional string uri = 3;
                      }

                    message OwnerV2 {
                      optional Data data = 1;
                    }

                    message Attributes {
                      optional string key = 1;
                      optional string value = 2;
                    }

                        message Profile {
                          optional string name = 1;
                        }

                      message Items {
                        optional Profile profile = 1;
                        optional string uri = 2;
                      }

                    message Artists {
                      repeated Items items = 1;
                    }

                        message ColorDark {
                          optional string hex = 1;
                          optional bool isFallback = 2;
                        }

                      message ExtractedColors {
                        optional ColorDark colorDark = 1;
                      }

                      message Sources {
                        optional int64 height = 1;
                        optional string url = 2;
                        optional int64 width = 3;
                      }

                    message CoverArt {
                      optional ExtractedColors extractedColors = 1;
                      repeated Sources sources = 2;
                    }

                    message Playability {
                      optional bool playable = 1;
                      optional string reason = 2;
                    }

                    message Profile {
                      optional string name = 1;
                    }

                          message ColorDark {
                            optional string hex = 1;
                            optional bool isFallback = 2;
                          }

                        message ExtractedColors {
                          optional ColorDark colorDark = 1;
                        }

                        message Sources {
                          optional int64 height = 1;
                          optional string url = 2;
                          optional int64 width = 3;
                        }

                      message AvatarImage {
                        optional ExtractedColors extractedColors = 1;
                        repeated Sources sources = 2;
                      }

                    message Visuals {
                      optional AvatarImage avatarImage = 1;
                    }

                    message Publisher {
                      optional string name = 1;
                    }

                              message Duration {
                                optional int64 nanoSeconds = 1;
                                optional int64 seconds = 2;
                              }

                            message ConsumptionExperienceTrait {
                              optional string __typename = 1;
                              optional Duration duration = 2;
                            }

                            message EntityTypeTrait {
                              optional string __typename = 1;
                              optional string type = 2;
                            }

                                message Items {
                                  optional string name = 1;
                                  optional string uri = 2;
                                }

                              message Contributors {
                                repeated Items items = 1;
                                optional int64 totalCount = 2;
                              }

                            message IdentityTrait {
                              optional string __typename = 1;
                              optional Contributors contributors = 2;
                              optional string description = 3;
                              optional string name = 4;
                              optional string type = 5;
                            }

                            message SharingInfo {
                              optional string shareId = 1;
                              optional string shareUrl = 2;
                            }

                            message TypedEntity {
                              optional string __typename = 1;
                            }

                                    message Sources {
                                      optional string imageFormat = 1;
                                      optional int64 maxHeight = 2;
                                      optional int64 maxWidth = 3;
                                      optional string url = 4;
                                    }

                                  message Data {
                                    optional string __typename = 1;
                                    repeated Sources sources = 2;
                                  }

                                message Image {
                                  optional Data data = 1;
                                }

                                  message FlatFile {
                                    optional string cdnUrl = 1;
                                  }

                                message OriginalInstances {
                                  optional FlatFile flatFile = 1;
                                  optional string size = 2;
                                }

                              message SquareCoverImage {
                                optional Image image = 1;
                                repeated OriginalInstances originalInstances = 2;
                              }

                            message VisualIdentityTrait {
                              optional string __typename = 1;
                              optional SquareCoverImage squareCoverImage = 2;
                            }

                          message Data {
                            optional string __typename = 1;
                            optional ConsumptionExperienceTrait consumptionExperienceTrait = 2;
                            optional EntityTypeTrait entityTypeTrait = 3;
                            optional IdentityTrait identityTrait = 4;
                            optional SharingInfo sharingInfo = 5;
                            optional TypedEntity typedEntity = 6;
                            optional string uri = 7;
                            optional VisualIdentityTrait visualIdentityTrait = 8;
                          }

                        message Entity {
                          optional string __typename = 1;
                          optional string _uri = 2;
                          optional Data data = 3;
                        }

                        message FormatListAttributes {
                          optional string key = 1;
                          optional string value = 2;
                        }

                      message Items {
                        optional Entity entity = 1;
                        repeated FormatListAttributes formatListAttributes = 2;
                        optional string uid = 3;
                      }

                    message Items {
                      repeated Items items = 1;
                      optional int64 totalCount = 2;
                    }

                    message ContentRating {
                      optional string label = 1;
                    }

                    message Duration {
                      optional int64 totalMilliseconds = 1;
                    }

                    message PlayedState {
                      optional int64 playPositionMilliseconds = 1;
                      optional string state = 2;
                    }

                            message ColorDark {
                              optional string hex = 1;
                              optional bool isFallback = 2;
                            }

                          message ExtractedColors {
                            optional ColorDark colorDark = 1;
                          }

                          message Sources {
                            optional int64 height = 1;
                            optional string url = 2;
                            optional int64 width = 3;
                          }

                        message CoverArt {
                          optional ExtractedColors extractedColors = 1;
                          repeated Sources sources = 2;
                        }

                        message Publisher {
                          optional string name = 1;
                        }

                        message ContentRatingV2 {
                          repeated string labels = 1;
                        }

                      message Data {
                        optional string __typename = 1;
                        optional CoverArt coverArt = 2;
                        optional string mediaType = 3;
                        optional string name = 4;
                        optional Publisher publisher = 5;
                        optional string uri = 6;
                        optional ContentRatingV2 contentRatingV2 = 7;
                      }

                    message PodcastV2 {
                      optional string __typename = 1;
                      optional Data data = 2;
                    }

                    message ReleaseDate {
                      optional string isoString = 1;
                      optional string precision = 2;
                    }

                    message Restrictions {
                      optional bool paywallContent = 1;
                    }

                          message Sources {
                            optional string imageFormat = 1;
                            optional int64 maxHeight = 2;
                            optional int64 maxWidth = 3;
                            optional string url = 4;
                          }

                        message Data {
                          optional string __typename = 1;
                          repeated Sources sources = 2;
                        }

                      message ImagePreview {
                        optional Data data = 1;
                      }

                    message VideoPreviewThumbnail {
                      optional string __typename = 1;
                      optional ImagePreview imagePreview = 2;
                    }

                          message EncoreBaseSetTextColor {
                            optional int64 alpha = 1;
                            optional int64 blue = 2;
                            optional int64 green = 3;
                            optional int64 red = 4;
                          }

                            message BackgroundBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message BackgroundTintedBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBrightAccent {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextSubdued {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                          message HighContrast {
                            optional BackgroundBase backgroundBase = 1;
                            optional BackgroundTintedBase backgroundTintedBase = 2;
                            optional TextBase textBase = 3;
                            optional TextBrightAccent textBrightAccent = 4;
                            optional TextSubdued textSubdued = 5;
                          }

                            message BackgroundBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message BackgroundTintedBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBrightAccent {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextSubdued {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                          message HigherContrast {
                            optional BackgroundBase backgroundBase = 1;
                            optional BackgroundTintedBase backgroundTintedBase = 2;
                            optional TextBase textBase = 3;
                            optional TextBrightAccent textBrightAccent = 4;
                            optional TextSubdued textSubdued = 5;
                          }

                            message BackgroundBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message BackgroundTintedBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBase {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextBrightAccent {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                            message TextSubdued {
                              optional int64 alpha = 1;
                              optional int64 blue = 2;
                              optional int64 green = 3;
                              optional int64 red = 4;
                            }

                          message MinContrast {
                            optional BackgroundBase backgroundBase = 1;
                            optional BackgroundTintedBase backgroundTintedBase = 2;
                            optional TextBase textBase = 3;
                            optional TextBrightAccent textBrightAccent = 4;
                            optional TextSubdued textSubdued = 5;
                          }

                        message ExtractedColorSet {
                          optional EncoreBaseSetTextColor encoreBaseSetTextColor = 1;
                          optional HighContrast highContrast = 2;
                          optional HigherContrast higherContrast = 3;
                          optional MinContrast minContrast = 4;
                        }

                      message SquareCoverImage {
                        optional string __typename = 1;
                        optional ExtractedColorSet extractedColorSet = 2;
                      }

                    message VisualIdentity {
                      optional SquareCoverImage squareCoverImage = 1;
                    }

                  message Data {
                    optional string __typename = 1;
                    optional Content content = 2;
                    optional string description = 3;
                    optional string format = 4;
                    optional Images images = 5;
                    optional string name = 6;
                    optional OwnerV2 ownerV2 = 7;
                    optional string uri = 8;
                    repeated Attributes attributes = 9;
                    optional Artists artists = 10;
                    optional CoverArt coverArt = 11;
                    optional bool isPreRelease = 12;
                    optional Playability playability = 13;
                    optional string albumType = 14;
                    optional Profile profile = 15;
                    optional Visuals visuals = 16;
                    optional string mediaType = 17;
                    optional Publisher publisher = 18;
                    optional Items items = 19;
                    optional ContentRating contentRating = 20;
                    optional Duration duration = 21;
                    optional string id = 22;
                    repeated string mediaTypes = 23;
                    optional PlayedState playedState = 24;
                    optional PodcastV2 podcastV2 = 25;
                    optional ReleaseDate releaseDate = 26;
                    optional Restrictions restrictions = 27;
                    optional string type = 28;
                    optional VideoPreviewThumbnail videoPreviewThumbnail = 29;
                    optional VisualIdentity visualIdentity = 30;
                  }

                message Content {
                  optional string __typename = 1;
                  optional string uri = 2;
                  optional Data data = 3;
                }

                message Data {
                  optional string __typename = 1;
                }

              message Items {
                optional Content content = 1;
                optional string uri = 2;
                optional Data data = 3;
              }

              message PagingInfo {
                optional int64 nextOffset = 1;
              }

            message SectionItems {
              repeated Items items = 1;
              optional PagingInfo pagingInfo = 2;
              optional int64 totalCount = 3;
            }

          message Items {
            optional Data data = 1;
            optional SectionItems sectionItems = 2;
            optional string uri = 3;
          }

        message Sections {
          repeated Items items = 1;
          optional int64 totalCount = 2;
        }

      message SectionContainer {
        optional Sections sections = 1;
        optional string uri = 2;
      }

        message Label {
          optional string transformedLabel = 1;
          optional string translatedBaseText = 2;
        }

          message Label {
            optional string transformedLabel = 1;
            optional string translatedBaseText = 2;
          }

        message SubChips {
          optional string id = 1;
          optional Label label = 2;
        }

      message HomeChips {
        optional string id = 1;
        optional Label label = 2;
        repeated SubChips subChips = 3;
      }

    message Home {
      optional string __typename = 1;
      optional Greeting greeting = 2;
      optional SectionContainer sectionContainer = 3;
      repeated HomeChips homeChips = 4;
    }

  message Data {
    optional Home home = 1;
  }

      message HomePath {
        optional string continuum = 1;
      }

    message ResponseIds {
      optional HomePath home_path = 1;
    }

  message Extensions {
    optional ResponseIds responseIds = 1;
  }

message CasitaResponse {
  optional Data data = 1;
  optional Extensions extensions = 2;
}
```
