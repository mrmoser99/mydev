/**
 * Test class for creating Term test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestTermBuilder {

    private String termDimension = 'Months';
    private String alias = 'Months';
    private Integer termValue = 12;

    private Boolean insertRecord = false;

    public TestTermBuilder withTermDimension(String termDimension) {
        this.termDimension = termDimension;
        return this;
    }

    public TestTermBuilder withAlias(String alias) {
        this.alias = alias;
        return this;
    }

    public TestTermBuilder withTermValue(Integer termValue) {
        this.termValue = termValue;
        return this;
    }

    public TestTermBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Term__c build() {
        Term__c testTerm = new Term__c(
            Term_Dimension__c = this.termDimension,
            Term_Value__c = this.termValue,
            Alias__c = this.alias
        );

        if(insertRecord) {
            insert testTerm;
        }

        return testTerm;
    }
}