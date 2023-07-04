@IsTest
public with sharing class SoftrigAuthProviderTest {
  private static final String STATE = 'mocktestState';
  private static final String OAUTH_TOKEN = 'testToken';
  private static final String REFRESH_TOKEN = 'refreshToken';
  private static final String ID_TOKEN = 'idToken';

  // private static final String LOGIN_ID = 'testLoginId';
  // private static final String USERNAME = 'testUsername';
  // private static final String FIRST_NAME = 'testFirstName';
  // private static final String LAST_NAME = 'testLastName';
  // private static final String EMAIL_ADDRESS = 'testEmailAddress';
  // private static final String LOCALE_NAME = 'testLocalName';
  // private static final String FULL_NAME = FIRST_NAME + ' ' + LAST_NAME;
  // private static final String PROVIDER = 'Concur';
  // private static final String KEY = 'testKey';

  private static final String REDIRECT_URL = 'https://computing-flow-9409-dev-ed.scratch.my.salesforce.com/services/authcallback/Softrig_Auth_Test';
  private static final String CLIENT_ID = 'ba855d83-ae61-458c-af45-b79314582c8e';
  private static final String SECRET = 'testSecret';
  private static final String STATE_TO_PROPOGATE = 'testState';
  private static final String SCOPE = 'AppFramework Administrator Sales.Admin openid profile offline_access';
  private static final String ACCESS_TOKEN_URL = 'http://www.dummyhost.com/accessTokenUri';
  private static final String API_USER_VERSION_URL = 'http://www.dummyhost.com/user/20/1';
  private static final String AUTH_URL = 'https://test-login.softrig.com/connect/authorize';
  private static final String TOKEN_URL = 'https://test-login.softrig.com/connect/token';
  private static final String API_USER_URL = 'www.concursolutions.com/user/api';

  // in the real world scenario , the key and value would be read from the (custom fields in) custom metadata type record
  private static Map<String, String> setupAuthProviderConfig() {
    Map<String, String> authProviderConfiguration = new Map<String, String>();
    authProviderConfiguration.put('Client_Id__c', CLIENT_ID);
    authProviderConfiguration.put('Auth_Url__c', AUTH_URL);
    authProviderConfiguration.put('Client_Secret__c', SECRET);
    authProviderConfiguration.put('Token_Url__c', TOKEN_URL);
    authProviderConfiguration.put('Scope__c', SCOPE);
    authProviderConfiguration.put('Redirect_Url__c', REDIRECT_URL);
    //authProviderConfiguration.put('API_User_Url__c',API_USER_URL);
    //authProviderConfiguration.put('Redirect_Url__c',REDIRECT_URL);
    return authProviderConfiguration;
  }

  @IsTest
  public static void testInitiate() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();

    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    Pagereference actualUrl = auth.initiate(
      authProviderConfiguration,
      STATE_TO_PROPOGATE
    );

    PageReference expectedUrl = new PageReference(
      authProviderConfiguration.get('Auth_Url__c') +
        '?client_id=' +
        authProviderConfiguration.get('Client_Id__c') +
        '&redirect_uri=' +
        REDIRECT_URL +
        '&response_type=code&prompt=login' +
        '&scope=' +
        SCOPE +
        '&state=' +
        STATE_TO_PROPOGATE
    );

    System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl());
  }

  @IsTest
  public static void testHandleCallback() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();

    String CODE = 'mycode1234';

    Map<String, String> queryParams = new Map<String, String>();
    queryParams.put('code', CODE);
    queryParams.put('state', STATE_TO_PROPOGATE);
    Auth.AuthProviderCallbackState state = new Auth.AuthProviderCallbackState(
      null,
      null,
      queryParams
    );

    String calloutUrl =
      TOKEN_URL +
      '?grant_type=authorization_code' +
      '&code=' +
      CODE +
      '&redirect_uri=' +
      REDIRECT_URL +
      '&client_id=' +
      CLIENT_ID +
      '&client_secret=' +
      SECRET;

    SoftrigCallbackMock mock = new SoftrigCallbackMock();
    mock.calloutUrl = calloutUrl;

    Test.setMock(HttpCalloutMock.class, mock);

    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    Auth.AuthProviderTokenResponse actualAuthProvResponse = auth.handleCallback(
      authProviderConfiguration,
      state
    );

    Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse(
      'Softrig Auth Test',
      OAUTH_TOKEN,
      REFRESH_TOKEN,
      STATE_TO_PROPOGATE
    );

    System.assertEquals(
      expectedAuthProvResponse.provider,
      actualAuthProvResponse.provider
    );
    System.assertEquals(
      expectedAuthProvResponse.oauthToken,
      actualAuthProvResponse.oauthToken
    );
    System.assertEquals(
      expectedAuthProvResponse.oauthSecretOrRefreshToken,
      actualAuthProvResponse.oauthSecretOrRefreshToken
    );
    System.assertEquals(
      expectedAuthProvResponse.state,
      actualAuthProvResponse.state
    );
  }

  class SoftrigCallbackMock implements HttpCalloutMock {
    public String calloutUrl;

    public HttpResponse respond(HttpRequest request) {
      System.assertEquals(calloutUrl, request.getEndpoint());

      HttpResponse response = new HttpResponse();
      String responseBody = JSON.serialize(
        new Map<String, Object>{
          'id_token' => ID_TOKEN,
          'access_token' => OAUTH_TOKEN,
          'expires_in' => 3600,
          'token_type' => 'Bearer',
          'refresh_token' => REFRESH_TOKEN
        }
      );
      response.setBody(responseBody);

      return response;
    }
  }

  @IsTest
  static void testGetUserInfo() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();
    SoftrigAuthProvider auth = new SoftrigAuthProvider();

    Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(
      'Softrig',
      OAUTH_TOKEN,
      REFRESH_TOKEN,
      null
    );
    Auth.UserData userData = auth.getUserInfo(
      authProviderConfiguration,
      response
    );
  }

  @IsTest
  static void testGetTokenValueFromResponse() {
    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    String res = auth.getTokenValueFromResponse('a', 'b');
  }
}
