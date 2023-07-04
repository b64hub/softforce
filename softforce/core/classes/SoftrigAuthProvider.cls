global class SoftrigAuthProvider extends Auth.AuthProviderPluginClass {
  public String redirectUrl; // use this URL for the endpoint that the authentication provider calls back to for configuration
  private String clientId;
  private String clientSecret;
  private String scope;
  private String state;
  private String authUrl; // application redirection to the Concur website for authentication and authorization
  private String tokenUrl; // uri to get the new access token from concur  using the GET verb
  private final String customMetadataTypeApiName = 'Softrig_Auth_Settings__mdt'; // api name for the custom metadata type created for this auth provider
  private String userAPIUrl; // api url to access the user in concur
  private String userAPIVersionUrl; // version of the user api url to access data from concur

  global String getCustomMetadataType() {
    return customMetadataTypeApiName;
  }

  global PageReference initiate(
    Map<string, string> authProviderConfiguration,
    String stateToPropagate
  ) {
    authUrl = authProviderConfiguration.get('Auth_Url__c');
    clientId = authProviderConfiguration.get('Client_Id__c');
    scope = authProviderConfiguration.get('Scope__c');
    state = authProviderConfiguration.get('State__c');
    redirectUrl = authProviderConfiguration.get('Redirect_Url__c');

    String url =
      authUrl +
      '?client_id=' +
      clientId +
      '&redirect_uri=' +
      this.redirectUrl +
      '&response_type=code&prompt=login' +
      '&scope=' +
      scope +
      '&state=' +
      stateToPropagate;

    return new PageReference(url);
  }

  global Auth.AuthProviderTokenResponse handleCallback(
    Map<string, string> authProviderConfiguration,
    Auth.AuthProviderCallbackState state
  ) {
    clientId = authProviderConfiguration.get('Client_Id__c');
    clientSecret = authProviderConfiguration.get('Client_Secret__c');
    tokenUrl = authProviderConfiguration.get('Token_Url__c');
    redirectUrl = authProviderConfiguration.get('Redirect_Url__c');

    Map<String, String> queryParams = state.queryParameters;
    String code = queryParams.get('code');
    String sfdcState = queryParams.get('state');

    HttpRequest req = new HttpRequest();
    String url = tokenUrl;

    String body =
      'grant_type=authorization_code' +
      '&code=' +
      code +
      '&redirect_uri=' +
      EncodingUtil.urlEncode(redirectUrl, 'UTF-8') +
      '&client_id=' +
      clientId +
      '&client_secret=' +
      clientSecret;
    req.setBody(body);
    req.setEndpoint(url);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();

    String accessToken = getTokenValueFromResponse(
      responseBody,
      'access_token'
    );
    String refreshToken = getTokenValueFromResponse(
      responseBody,
      'refresh_token'
    );

    return new Auth.AuthProviderTokenResponse(
      'Softrig',
      accessToken,
      refreshToken,
      sfdcState
    );
  }

  global override Auth.OAuthRefreshResult refresh(
    Map<String, String> authProviderConfiguration,
    String refreshToken
  ) {
    clientId = authProviderConfiguration.get('Client_Id__c');
    clientSecret = authProviderConfiguration.get('Client_Secret__c');
    tokenUrl = authProviderConfiguration.get('Token_Url__c');
    redirectUrl = authProviderConfiguration.get('Redirect_Url__c');

    HttpRequest req = new HttpRequest();
    String url = tokenUrl;

    req.setEndpoint(url);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    String body =
      'grant_type=refresh_token' +
      '&refresh_token=' +
      refreshToken +
      '&redirect_uri=' +
      EncodingUtil.urlEncode(redirectUrl, 'UTF-8') +
      '&client_id=' +
      clientId +
      '&client_secret=' +
      clientSecret;
    req.setBody(body);

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    String accessToken = getTokenValueFromResponse(
      responseBody,
      'access_token'
    );
    String newRefreshToken = getTokenValueFromResponse(
      responseBody,
      'refresh_token'
    );

    return new Auth.OAuthRefreshResult(accessToken, newRefreshToken);
  }

  global Auth.UserData getUserInfo(
    Map<string, string> authProviderConfiguration,
    Auth.AuthProviderTokenResponse response
  ) {
    //Here the developer is responsible for constructing an Auth.UserData object
    //   String token = response.oauthToken;
    //   HttpRequest req = new HttpRequest();
    //   userAPIUrl = authProviderConfiguration.get('API_User_Url__c');
    //   userAPIVersionUrl = authProviderConfiguration.get('API_User_Version_Url__c');
    //   req.setHeader('Authorization', 'OAuth ' + token);
    //   req.setEndpoint(userAPIUrl);
    //   req.setHeader('Content-Type','application/xml');
    //   req.setMethod('GET');

    //   Http http = new Http();
    //   HTTPResponse res = http.send(req);
    //   String responseBody = res.getBody();
    //   String id = getTokenValueFromResponse(responseBody, 'LoginId',userAPIVersionUrl);
    //   String fname = getTokenValueFromResponse(responseBody, 'FirstName', userAPIVersionUrl);
    //   String lname = getTokenValueFromResponse(responseBody, 'LastName', userAPIVersionUrl);
    //   String flname = fname + ' ' + lname;
    //   String uname = getTokenValueFromResponse(responseBody, 'EmailAddress', userAPIVersionUrl);
    //   String locale = getTokenValueFromResponse(responseBody, 'LocaleName', userAPIVersionUrl);
    Map<String, String> provMap = new Map<String, String>();
    provMap.put('oauthToken', response.oauthToken);
    provMap.put('state', response.state);
    provMap.put('refreshToken', response.oauthSecretOrRefreshToken);
    return new Auth.UserData(
      UserInfo.getUserId(),
      UserInfo.getFirstName(),
      UserInfo.getLastName(),
      UserInfo.getName(),
      UserInfo.getUserEmail(),
      null,
      UserInfo.getUserName(),
      UserInfo.getLocale(),
      'Softrig Auth Test',
      null,
      provMap
    );
  }

  @TestVisible
  private String getTokenValueFromResponse(String response, String token) {
    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(
      response
    );
    String value = (String) res.get(token);
    return value;
  }
}