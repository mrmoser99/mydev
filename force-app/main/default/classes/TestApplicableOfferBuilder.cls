@isTest
public class TestApplicableOfferBuilder {

    private String name = 'Tractor Applicable Offer';
    private Id accountId;
    private Id offerId;

    private Boolean insertRecord = false;

    public TestApplicableOfferBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestApplicableOfferBuilder withAccount(Id accountId) {
        this.accountId = accountId;
        return this;
    }

    public TestApplicableOfferBuilder withOffer(Id offerId) {
        this.offerId = offerId;
        return this;
    }

    public TestApplicableOfferBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Applicable_Offer__c build() {
        Applicable_Offer__c testApplicableOffer = new Applicable_Offer__c(
            Name = this.name,
            Account__c = this.accountId,
            Offer__c = this.offerId
        );

        if(insertRecord) {
            insert testApplicableOffer;
        }

        return testApplicableOffer;
    }

}