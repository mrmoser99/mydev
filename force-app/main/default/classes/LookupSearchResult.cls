/**
 * Class used to serialize a single Lookup search result item
 * The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
 */
public class LookupSearchResult implements Comparable {
    public Id id;
    public String sObjectType;
    public String icon;
    public String title;
    public String subtitle;
    public String productType;
    public boolean isItadApplicable;   
    public boolean isPurchaseOptionAvailable = false;
    public boolean isInsuranceAvailable = false;
    public boolean isProductAvailable = true;

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, String productType) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.productType = productType;
    }

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, String productType, Boolean isItadApplicable) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.productType = productType;
        this.isItadApplicable = isItadApplicable;
    }

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, String productType, Boolean isItadApplicable, Boolean isProductAvailable) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.productType = productType;
        this.isItadApplicable = isItadApplicable;
        this.isProductAvailable = isProductAvailable;
    }

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, String productType, Boolean isItadApplicable,
                              Boolean isPurchaseOptionAvailable, Boolean isInsuranceAvailable, Boolean isProductAvailable) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.productType = productType;
        this.isItadApplicable = isItadApplicable;
        this.isPurchaseOptionAvailable = isPurchaseOptionAvailable;
        this.isInsuranceAvailable = isInsuranceAvailable;
        this.isProductAvailable = isProductAvailable;
    }

    
    @AuraEnabled
    public String getProductType() {
        return productType;
    }

    @AuraEnabled
    public Id getId() {
        return id;
    }

    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

    @AuraEnabled
    public String getIcon() {
        return icon;
    }

    @AuraEnabled
    public String getTitle() {
        return title;
    }

    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }

    @AuraEnabled
    public boolean getIsItadApplicable() {
        return isItadApplicable;
    }

    @AuraEnabled
    public boolean getisProductAvailable() {
        return isProductAvailable;
    }
    
    @AuraEnabled
    public boolean getIsPurchaseOptionAvailable() {
        return isPurchaseOptionAvailable;
    }
    
    @AuraEnabled
    public boolean getIsInsuranceAvailable() {
        return isInsuranceAvailable;
    }

    /**
     * Allow to sort search results based on title
     */
    public Integer compareTo(Object compareTo) {
        LookupSearchResult other = (LookupSearchResult) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }

}