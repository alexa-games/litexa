/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

/*
 * Litexa Configuration File Definitions
 */
interface PluginCollection {
    [key: string]: object;
}

interface DeploymentCollection {
    [key: string]: Deployment;
}

type InvocationCollection = {[key in Region | Locale]: string}

interface LambdaSettings {
    Environment?: {
        Variables?: {
            [key: string]: string
        }
    };
    MemorySize?: number;
    Timeout?: number;
}

type DeploymentVariables = {[key: string]: boolean | number | string | object | Array<boolean | number | string | object> }

interface S3Configuration {
    bucketName: string;
    uploadParams?: UploadParams[];
}

interface UploadParams {
    filter?: string[];
    params: { [key: string]: any };
}

interface Deployment {
    module: string;
    askProfile: string;
    awsProfile: string;
    lambdaConfiguration?: LambdaSettings;
    s3Configuration: S3Configuration;
    S3BucketName?: string;  // Deprecated. Now using s3Configuration.bucketName.
    invocationSuffix?: string;
    invocation?: InvocationCollection;
    DEPLOY?: DeploymentVariables;
    disableAssetReferenceValidation?: boolean;
    overrideAssetsRoot?: string;
}

interface Configuration {
    name: string;
    deployments: DeploymentCollection;
    plugins: PluginCollection; // Per Environment Option?
}

/*
 * Skill Manifest File Definitions
 */
interface Permission {
    name: string;
}

type SkillEvent = 'SKILL_ENABLED' | 'SKILL_DISABLED' | 'SKILL_PERMISSION_ACCEPTED' | 'SKILL_PERMISSION_CHANGED' | 'SKILL_ACCOUNT_LINKED';
interface Subscription {
    eventName: SkillEvent;
}

type ProactiveEvent = string;
interface Publication {
    eventName: ProactiveEvent;
}

interface Endpoint {
    uri: string;
}

type Region = 'AU' | 'CA' | 'IN' | 'UK' | 'US' | 'FR' | 'DE' | 'IT' | 'JP' | 'ES' | 'MX';
type Regions = { [key in Region]?: Endpoint };

interface Target {
    endpoint: Endpoint;
    region: Regions;
}

interface SubcriptionEvents extends Target {
    subscriptions: Subscription[];
}

interface PublicationEvents extends Target {
    publications: Publication[];
}

interface AllEvents extends Target {
    publications: Publication[];
    subscriptions: Subscription[];
}

type Events = SubcriptionEvents | PublicationEvents | AllEvents;
type Locale = 'de-DE' | 'en-AU' | 'en-CA' | 'en-GB' | 'en-IN' | 'en-US' | 'es-ES' | 'es-MX' | 'fr-CA' | 'fr-FR' | 'it-IT' | 'ja-JP';

interface PublishingLocale {
    name?: string;
    invocation?: string;
    summary: string;
    description: string;
    smallIconUri?: string;
    largeIconUri?: string;
    examplePhrases: string[];
    keywords: string[];
    updatesDescription?: string;
}

type PublishingLocales = { [key in Locale]?: PublishingLocale };
type Category = 'ALARMS_AND_CLOCKS' | 'ASTROLOGY' | 'BUSINESS_AND_FINANCE' | 'CALCULATORS' | 'CALENDARS_AND_REMINDERS' | 'CHILDRENS_EDUCATION_AND_REFERENCE' | 'CHILDRENS_GAMES' | 'CHILDRENS_MUSIC_AND_AUDIO' | 'CHILDRENS_NOVELTY_AND_HUMOR' | 'COMMUNICATION' | 'CONNECTED_CAR' | 'COOKING_AND_RECIPE' | 'CURRENCY_GUIDES_AND_CONVERTERS' | 'DATING' | 'DELIVERY_AND_TAKEOUT' | 'DEVICE_TRACKING' | 'EDUCATION_AND_REFERENCE' | 'EVENT_FINDERS' | 'EXERCISE_AND_WORKOUT' | 'FASHION_AND_STYLE' | 'FLIGHT_FINDERS' | 'FRIENDS_AND_FAMILY' | 'GAME_INFO_AND_ACCESSORY' | 'GAMES' | 'HEALTH_AND_FITNESS' | 'HOTEL_FINDERS' | 'KNOWLEDGE_AND_TRIVIA' | 'MOVIE_AND_TV_KNOWLEDGE_AND_TRIVIA' | 'MOVIE_INFO_AND_REVIEWS' | 'MOVIE_SHOWTIMES' | 'MUSIC_AND_AUDIO_ACCESSORIES' | 'MUSIC_AND_AUDIO_KNOWLEDGE_AND_TRIVIA' | 'MUSIC_INFO_REVIEWS_AND_RECOGNITION_SERVICE' | 'NAVIGATION_AND_TRIP_PLANNER' | 'NEWS' | 'NOVELTY' | 'ORGANIZERS_AND_ASSISTANTS' | 'PETS_AND_ANIMAL' | 'PODCAST' | 'PUBLIC_TRANSPORTATION' | 'RELIGION_AND_SPIRITUALITY' | 'RESTAURANT_BOOKING_INFO_AND_REVIEW' | 'SCHOOLS' | 'SCORE_KEEPING' | 'SELF_IMPROVEMENT' | 'SHOPPING' | 'SMART_HOME' | 'SOCIAL_NETWORKING' | 'SPORTS_GAMES' | 'SPORTS_NEWS' | 'STREAMING_SERVICE' | 'TAXI_AND_RIDESHARING' | 'TO_DO_LISTS_AND_NOTES' | 'TRANSLATORS' | 'TV_GUIDES' | 'UNIT_CONVERTERS' | 'WEATHER' | 'WINE_AND_BEVERAGE' | 'ZIP_CODE_LOOKUP';

interface PublishingInformation {
    locales: PublishingLocales;
    isAvailableWorldwide: boolean; // @TODO - if this is true then require distributionCountries
    distributionCountries: string[];
    distributionMode: 'PUBLIC' | 'PRIVATE';
    testingInstructions: string;
    category: Category;
}

interface PrivacyLocale {
    privacyPolicyUrl: string;
    termsOfUseUrl: string;
}
type PrivacyLocales = { [key in Locale]?: PrivacyLocale };

interface PrivacyCompliance {
    allowsPurchases: boolean;
    usesPersonalInfo: boolean;
    isChildDirected: boolean; // @TODO - Definition for if true PublishingInformation.category has to be certain things: Add Type Protection
    isExportCompliant: boolean;
    containsAds: boolean;
    locales: PrivacyLocales;

}

type SSLCertificate = 'SelfSigned' | 'Trusted' | 'Wildcard';
interface StrictEndpoint extends Endpoint {
    sslCertificateType: SSLCertificate;
}
type StrictRegions = { [key in Region]?: StrictEndpoint };
type CustomInterface = 'ALEXA_PRESENTATION_HTML' | 'ALEXA_PRESENTATION_APL' | 'AUDIO_PLAYER' | 'CAN_FULFILL_INTENT_REQUEST' | 'GADGET_CONTROLLER' | 'GAME_ENGINE' | 'RENDER_TEMPLATE' | 'VIDEO_APP';
interface Interface {
    type: CustomInterface;
}

type HouseholdListAPI = {}; // @TODO - Find Definition for HouseholdListAPI
interface CustomAPI {
    endpoint: StrictEndpoint;
    regions: StrictRegions;
    interfaces: Interface[];
}
type UpdateFrequency = 'DAILY' | 'HOURLY' | 'WEEKLY';
type ContentGenre = 'HEADLINE_NEWS' | 'BUSINESS' | 'POLITICS' | 'ENTERTAINMENT' | 'TECHNOLOGY' | 'HUMOR' | 'LIFESTYLE' | 'SPORTS' | 'SCIENCE' | 'HEALTH_AND_FITNESS' | 'ARTS_AND_CULTURE' | 'PRODUCTIVITY_AND_UTILITIES' | 'OTHER';
type ContentType = 'TEXT' | 'AUDIO';
interface Feed {
    name: string;
    isDefault: boolean;
    vuiPreamble: string;
    updateFrequency: UpdateFrequency;
    genre: ContentGenre;
    imageUri: string;
    contentType: ContentType;
    url: string;
}
interface FlashBriefingLocale {
    customErrorMessage: string;
    feeds: Feed[];
}
type FlashBriefingAPI = { [key in Locale]?: FlashBriefingLocale };

type MusicAPI = {}; // @TODO - Find Definition for MusicAPI

interface SmartHomeAPI extends Target {
    protocolVersion?: string;
}

interface UpChannel {
    type: string;
    uri: string;
}

interface VideoRegion {
    endpoint: Endpoint;
    upchannel: UpChannel;
}

type VideoRegions = { [key in Region]?: VideoRegion };

interface VideoLocale {
    videoProviderTargetingNames: string[];
    catalogInformation?: any[]; // Not Documented Properly
}

type VideoLocales = { [key in Locale]?: VideoLocale };

interface VideoAPI {
    locales: VideoLocales;
    endpoint: Endpoint; // Not Documented Properly
    regions: VideoRegions;
}

type APIDefinition = CustomAPI | FlashBriefingAPI | HouseholdListAPI | MusicAPI | SmartHomeAPI | VideoAPI;
type API = 'custom' | 'flashBriefing' | 'householdList' | 'music' | 'smartHome' | 'video';
type APIs = { [key in API]?: APIDefinition };

interface Manifest {
    manifestVersion?: string;
    publishingInformation: PublishingInformation;
    privacyAndCompliance: PrivacyCompliance;
    permissions?: Permission[];
    events?: Events;
    apis?: APIs;
}
