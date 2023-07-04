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
    this.authUrl = authProviderConfiguration.get('Auth_Url__c');
    this.clientId = authProviderConfiguration.get('Client_Id__c');
    this.scope = authProviderConfiguration.get('Scope__c');
    this.state = authProviderConfiguration.get('State__c');
    this.redirectUrl = authProviderConfiguration.get('Redirect_Url__c');
    //Here the developer can build up a request of some sort
    //Ultimately they’ll return a URL where we will redirect the user
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
    System.debug(url);
    return new PageReference(url);
  }

  global Auth.AuthProviderTokenResponse handleCallback(
    Map<string, string> authProviderConfiguration,
    Auth.AuthProviderCallbackState state
  ) {
    //Here, the developer will get the callback with actual protocol.
    //Their responsibility is to return a new object called AuthProviderToken
    //This will contain an optional accessToken and refreshToken

    Logger.info('In callback mode');
    //Logger.info(authProviderConfiguration);
    //Logger.info(state);

    clientId = authProviderConfiguration.get('Client_Id__c');
    clientSecret = authProviderConfiguration.get('Client_Secret__c');
    tokenUrl = authProviderConfiguration.get('Token_Url__c');
    redirectUrl = authProviderConfiguration.get('Redirect_Url__c');

    Map<String, String> queryParams = state.queryParameters;
    String code = queryParams.get('code');
    String sfdcState = queryParams.get('state');

    Logger.info('Code received: ' + code);

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
    Logger.info('Request body: ' + body);
    req.setBody(body);
    req.setEndpoint(url);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');

    Logger.info('Making request to endpoint ' + url);
    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    Logger.info('Response:' + responseBody);

    String accessToken = getTokenValueFromResponse(
      responseBody,
      'access_token'
    );
    //Parse access token value
    String refreshToken = getTokenValueFromResponse(
      responseBody,
      'refresh_token'
    );
    //Parse refresh token value

    Logger.info('access_token: ' + accessToken);
    Logger.info('refresh_token: ' + refreshToken);
    Logger.saveLog();

    //Logger.info('Received access token: ' + accessToken.left(20) + '...');
    //Logger.info('Received refresh token: ' + refreshToken.left(20) + '...');

    //Logger.saveLog();
    //don’t hard-code the refresh token value!
    return new Auth.AuthProviderTokenResponse(
      'Softrig Auth Test',
      accessToken,
      refreshToken,
      sfdcState
    );
  }

  global override Auth.OAuthRefreshResult refresh(
    Map<String, String> authProviderConfiguration,
    String refreshToken
  ) {
    Logger.info('Refresh token');
    Logger.saveLog();

    clientId = authProviderConfiguration.get('Client_Id__c');
    clientSecret = authProviderConfiguration.get('Client_Secret__c');
    tokenUrl = authProviderConfiguration.get('Token_Url__c');
    redirectUrl = authProviderConfiguration.get('Redirect_Url__c');

    HttpRequest req = new HttpRequest();
    String url = tokenUrl;

    req.setEndpoint(url);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    String body = EncodingUtil.urlEncode(
      'grant_type=refresh_token' +
        '&refresh_token=' +
        refreshToken +
        '&redirect_uri=' +
        redirectUrl +
        '&client_id=' +
        clientId +
        '&client_secret=' +
        clientSecret,
      'UTF-8'
    );
    Logger.info('Request body: ' + body);
    req.setBody(body);

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    String accessToken = getTokenValueFromResponse(
      responseBody,
      'access_token'
    );
    //Parse access token value
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
    Logger.info('get user info');
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
    Logger.saveLog();
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
    System.debug('get token value');
    System.debug(response);
    System.debug(token);

    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(
      response
    );
    String value = (String) res.get(token);

    //  Dom.Document docx = new Dom.Document();
    //  docx.load(response);
    //  String ret = null;

    //  dom.XmlNode xroot = docx.getrootelement() ;
    //  if(xroot != null){
    //     ret = xroot.getChildElement(token, ns).getText();
    //  }
    return value;
  }
}
