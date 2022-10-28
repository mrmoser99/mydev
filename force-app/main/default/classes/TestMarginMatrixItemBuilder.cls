/**
 * Test class for creating MarginMatrixItem test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestMarginMatrixItemBuilder {
    
    Id termId;
    Id marginMatrixId;
    Decimal amount = 0;
    Decimal value = 1;

    private Boolean insertRecord = false;

    public TestMarginMatrixItemBuilder withTerm(Id termId) {
        this.termId = termId;
        return this;
    }

    public TestMarginMatrixItemBuilder withMarginMatrix(Id marginMatrixId) {
        this.marginMatrixId = marginMatrixId;
        return this;
    }

    public TestMarginMatrixItemBuilder withAmount(Decimal amount) {
        this.amount = amount;
        return this;
    }

    public TestMarginMatrixItemBuilder withValue(Decimal value) {
        this.value = value;
        return this;
    }

    public TestMarginMatrixItemBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Margin_Matrix_Item__c build() {
        Margin_Matrix_Item__c marginMatrixItem = new Margin_Matrix_Item__c(
            Margin_Matrix__c = this.marginMatrixId,
            Term__c = this.termId,
            Financial_Amount__c = this.amount,
            Value__c = this.value
        );

        if (insertRecord) {
            insert marginMatrixItem;
        }

        return marginMatrixItem;
    }
}