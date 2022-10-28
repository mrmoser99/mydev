/**
 * Test class for MarginMatrix test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestMarginMatrixBuilder {
    
    Id termId;
    String name;

    private Boolean insertRecord = false;

    public TestMarginMatrixBuilder withTerm(Id termId) {
        this.termId = termId;
        return this;
    }

    public TestMarginMatrixBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestMarginMatrixBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Margin_Matrix__c build() {
        Margin_Matrix__c marginMatrix = new Margin_Matrix__c(
            Name = name,
            Max_Term__c = termId
        );

        if (insertRecord) {
            insert marginMatrix;
        }

        return marginMatrix;
    }
}