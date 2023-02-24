//This class has issue with nominal rate; therea are duplicate nominal rates
//

public class JSONFinancialProduct {


     public Data data;
     public Pagination pagination;

     public class Interest_Z {
          public Nominalrate nominalrate;
     }

     public class Percentages {
          public String id;
          public Inputs_Z inputs;
          public Outputs_Z outputs;
     }

     public class EarlyTermination {
          public Boolean allowed;
     }

     public class Finance {
          public FinanceAmount financeAmount;
          public Interest interest;
          public RateFactors rateFactors;
     }

     public class Values {
          public Inputs inputs;
          public Outputs outputs;
          public Integer minimum;
          public Integer maximum;
     }

     public class Duration {
          public NumberOfMonths numberOfMonths;
          public EarlyTermination earlyTermination;
     }

     public class Data {
          public String id;
          public String url;
          public String name;
          public String modificationDateTime;
          public Integer calculationValidity;
          public String purchaseOption;
          public Duration duration;
          public Finance finance;
          public Subsidies subsidies;
     }

     public class FinanceAmount {
          public Decimal minimum;
          public Decimal maximum;
     }

     public class Inputs_Z {
          public String paymentFrequency;
          public String paymentTiming;
          public Integer numberOfMonths;
          public Integer initialDelay;
          public Integer initialPaymentMultiplier;
          public Integer securityDepositMultiplier;
          public Decimal financeAmount;
          public List<String> assetConditions;
          public List<String> assetBrandNames;
          public List<String> assetModelNames;
     }

     public class Outputs_Z {
          public Integer default_Z; // in json: default
     }

     public class NominalRate {
          public String id;
          public String name;
          public String compoundingFrequency;
          public String interpolation;
          public List<Percentages> percentages;
     }

     public class Interest {
          public NominalRate nominalRate;
     }

     public class NominalRate_Z {
          public String id;
          public String name;
          public String interpolation;
          public List<Percentages> factors;
     }

     public class Pagination {
          public Integer page;
          public Integer pageSize;
          public Integer itemCount;
          public Integer pageCount;
          public Links links;
     }

     public class RateFactors {
          public NominalRate_Z nominalRate;
     }

     public class NumberOfMonths {
          public String id;
          public String name;
          public List<Values> values;
     }

     public class Outputs {
          public Integer default_Z; // in json: default
          public Integer minimum;
          public Integer maximum;
          public List<Integer> allowed;
     }

     public class Subsidies {
          public List<Dealer> dealer;
          public List<Dealer> manufacturer;
     }

     public class Links {
          public String self;
          public String first;
          public String next;
          public String prev;
          public String last;
     }

     public class Inputs {
          public String paymentFrequency;
     }

     public class Dealer {
          public String id;
          public String name;
          public String description;
          public Integer maximumAmount;
          public Integer maximumPercentage;
          public String maximumPercentageOf;
          public Interest_Z interest;
     }
}