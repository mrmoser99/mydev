/**
 * Class creates the JSON response of third party system for Access Token
 */
public with sharing class GenerateTokenResponseBodyWrapper extends BaseResponseBodyWrapper {

    public String access_token;
    public Integer expires_on;
}