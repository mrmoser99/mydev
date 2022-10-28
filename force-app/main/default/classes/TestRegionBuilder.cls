/**
 * Test class for creating Region test data 
 * Version 1.0
 */
@isTest
public class TestRegionBuilder {

    private String name = 'Sweden';
    private String isoCode = 'SE';
    private String type = 'Country';
    private Id regionId;
    private Boolean Active = false;
    
    private Boolean insertRecord = false;

    public TestRegionBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestRegionBuilder withIsoCode(String isoCode) {
        this.isoCode = isoCode;
        return this;
    }

    public TestRegionBuilder withType(String type) {
        this.type = type;
        return this;
    } 
    
    public TestRegionBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }
    
     public TestRegionBuilder withActive(Boolean Active) {
        this.Active = Active;
        return this;
    }

    public Region__c build() {

        Region__c testRegion = new Region__c(
            Name = this.name,
            ISO_Code__c = this.isoCode,
            Region_Type__c = this.type,
            Active__c= this.Active
        );

        if(insertRecord) {
            insert testRegion;
        }
        return testRegion;
    }
}