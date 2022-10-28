/**
 * This class is used as apex controller for Opportunity Graph VF-page (Home screen)
 * 
 * @author Elena Sokolova @date 2020-12-15
 */
public with sharing class OpportunityGraphController {
    private String currencyCode;
    private static final String REPORT_NAME = 'Opportunity_Amount_By_Stage';

    public OpportunityGraphController() {
        this.currencyCode = new WoSSelector().getDefaultOfferCurrencyCodeByUserId(UserInfo.getUserId());
    }

    /**
     * reportApiName is used as attribute for analytics:reportChart conponent.
     * It's the unique developer name of the report. Separate report has been created for each currency type
     */
    public String getReportApiName() {
        return REPORT_NAME + '_' + this.currencyCode;
    }

    /**
     * Inner class-selector without sharing
     */
    private without sharing class WoSSelector {
        private String getDefaultOfferCurrencyCodeByUserId(String userId) {
            return [
                SELECT  Contact.Account.PartnerOffer__r.Offer__r.CurrencyIsoCode
                FROM    User
                WHERE   Id =:userId
            ].Contact.Account.PartnerOffer__r.Offer__r.CurrencyIsoCode;
        }
    }
 
}