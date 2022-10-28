/**
 * This class is used in RESTCallout service class to create callout and set params. 
 * It provide request body wrapper for Search Party callout
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public with sharing class SearchPartyRequestBodyWrapper extends BaseRequestBodyWrapper {

    public String unique_identifier;
    public String unique_identifier_type;
    public String country_of_registration;

    public SearchPartyRequestBodyWrapper() {}

    /**
     * Method sets class variables.
     * Override the parent class method with this signature.
     */
    public override void init(Map<String, Object> params) {

        super.init(params);

        this.unique_identifier          = (String) params.get('externalOrganizationId');
        this.unique_identifier_type     = (String) params.get('uniqueIdentifierType');
        this.country_of_registration    = (String) params.get('countryOfRegistration');
    }
}