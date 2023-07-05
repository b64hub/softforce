@IsTest
public with sharing class SoftrigAuthProviderTest {
  private static final String STATE = 'mocktestState';
  private static final String OAUTH_TOKEN = 'testToken';
  private static final String REFRESH_TOKEN = 'refreshToken';
  private static final String NEW_REFRESH_TOKEN = 'newSuperfreshRefreshToken';
  private static final String ID_TOKEN = 'idToken';
  private static final String REDIRECT_URL = 'https://computing-flow-9409-dev-ed.scratch.my.salesforce.com/services/authcallback/Softrig';
  private static final String CLIENT_ID = 'testClientId';
  private static final String SECRET = 'testSecret';
  private static final String STATE_TO_PROPOGATE = 'testState';
  private static final String SCOPE = 'AppFramework openid profile offline_access';
  private static final String AUTH_URL = 'https://test-login.softrig.com/connect/authorize';
  private static final String TOKEN_URL = 'https://test-login.softrig.com/connect/token';
  private static final String API_USER_URL = 'https://test-login.softrig.com/connect/token';

  private static Map<String, String> setupAuthProviderConfig() {
    Map<String, String> authProviderConfiguration = new Map<String, String>();
    authProviderConfiguration.put('Client_Id__c', CLIENT_ID);
    authProviderConfiguration.put('Client_Secret__c', SECRET);
    authProviderConfiguration.put('Auth_Url__c', AUTH_URL);
    authProviderConfiguration.put('Token_Url__c', TOKEN_URL);
    authProviderConfiguration.put('Scope__c', SCOPE);
    authProviderConfiguration.put('Redirect_Url__c', REDIRECT_URL);
    return authProviderConfiguration;
  }

  @IsTest
  public static void testInitiate() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();

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

    Test.startTest();
    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    Pagereference actualUrl = auth.initiate(
      authProviderConfiguration,
      STATE_TO_PROPOGATE
    );
    Test.stopTest();

    System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl());
  }

  @IsTest
  public static void testHandleCallback() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();

    String CODE = 'testCode';

    Map<String, String> queryParams = new Map<String, String>();
    queryParams.put('code', CODE);
    queryParams.put('state', STATE_TO_PROPOGATE);
    Auth.AuthProviderCallbackState state = new Auth.AuthProviderCallbackState(
      null,
      null,
      queryParams
    );

    SoftrigCallbackMock mock = new SoftrigCallbackMock();
    mock.expectedCalloutUrl = TOKEN_URL;
    mock.expectedBody =
      'grant_type=authorization_code' +
      '&code=' +
      CODE +
      '&redirect_uri=' +
      EncodingUtil.urlEncode(REDIRECT_URL, 'UTF-8') +
      '&client_id=' +
      CLIENT_ID +
      '&client_secret=' +
      SECRET;

    Test.setMock(HttpCalloutMock.class, mock);
    Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse(
      'Softrig',
      OAUTH_TOKEN,
      REFRESH_TOKEN,
      STATE_TO_PROPOGATE
    );

    Test.startTest();
    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    Auth.AuthProviderTokenResponse actualAuthProvResponse = auth.handleCallback(
      authProviderConfiguration,
      state
    );
    Test.stopTest();

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

  @IsTest
  static void testRefresh() {
    Map<String, String> authProviderConfiguration = SoftrigAuthProviderTest.setupAuthProviderConfig();

    SoftrigRefreshMock mock = new SoftrigRefreshMock();
    mock.expectedCalloutUrl = TOKEN_URL;
    mock.expectedBody =
      'grant_type=refresh_token' +
      '&refresh_token=' +
      REFRESH_TOKEN +
      '&redirect_uri=' +
      EncodingUtil.urlEncode(REDIRECT_URL, 'UTF-8') +
      '&client_id=' +
      CLIENT_ID +
      '&client_secret=' +
      SECRET;

    Auth.OAuthRefreshResult expectedResult = new Auth.OAuthRefreshResult(
      OAUTH_TOKEN,
      NEW_REFRESH_TOKEN
    );

    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    Auth.OAuthRefreshResult actualResult = auth.refresh(
      authProviderConfiguration,
      REFRESH_TOKEN
    );
    Test.stopTest();

    System.assertEquals(
      expectedResult.refreshToken,
      actualResult.refreshToken,
      'Unequal refresh tokens'
    );
    System.assertEquals(
      expectedResult.accessToken,
      actualResult.accessToken,
      'Unequal access tokens'
    );
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
    String responseBody = JSON.serialize(
      new Map<String, Object>{
        'id_token' => ID_TOKEN,
        'access_token' => OAUTH_TOKEN,
        'expires_in' => 3600,
        'token_type' => 'Bearer',
        'refresh_token' => REFRESH_TOKEN
      }
    );

    Test.startTest();
    SoftrigAuthProvider auth = new SoftrigAuthProvider();
    String token = auth.getTokenValueFromResponse(responseBody, 'access_token');
    Test.stopTest();

    System.assertEquals(OAUTH_TOKEN, token, 'Wrong value from response');
  }

  class SoftrigCallbackMock implements HttpCalloutMock {
    public String expectedCalloutUrl;
    public String expectedBody;

    public HttpResponse respond(HttpRequest request) {
      System.assertEquals(expectedCalloutUrl, request.getEndpoint());
      System.assertEquals(expectedBody, request.getBody());

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

  class SoftrigRefreshMock implements HttpCalloutMock {
    public String expectedCalloutUrl;
    public String expectedBody;

    public HttpResponse respond(HttpRequest request) {
      System.assertEquals(expectedCalloutUrl, request.getEndpoint());
      System.assertEquals(expectedBody, request.getBody());

      HttpResponse response = new HttpResponse();
      String responseBody = JSON.serialize(
        new Map<String, Object>{
          'id_token' => ID_TOKEN,
          'access_token' => OAUTH_TOKEN,
          'expires_in' => 3600,
          'token_type' => 'Bearer',
          'refresh_token' => NEW_REFRESH_TOKEN
        }
      );
      response.setBody(responseBody);

      return response;
    }
  }
}
