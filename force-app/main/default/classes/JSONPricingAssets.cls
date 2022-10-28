public class JSONPricingAssets {

public class Pagination {
public Integer page;
public Integer pageSize;
public Integer itemCount;
public Integer pageCount;
public Links links;
}

public List<Data> data;
public Pagination pagination;

public class Links {
public String self;
public String first;
public String next;
public String prev;
public String last;
}

public class Data {
public String id;
public Catalog catalog;
}

public class Structure {
public String masterType;
public String category;
public String type;
public String brand;
public String model;
}

public class Identifiers {
public Structure structure;
}

public class Catalog {
public String id;
public String name;
public Identifiers identifiers;
public Integer econimicLife;
public Integer listPrice;
}

public static void testRun(){
	Integer i = 0;
	i++;

}

}