var config = require('./dbconfig');
const sql= require('mssql');


    async function getCustomers(){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request().query("SELECT * from CUSTOMER");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getFfc(){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request().query("SELECT * from FFC");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getCustomer(Customer_number){
            try{
                let pool = await sql.connect(config);
                let products = await pool.request()
                .input('input_parameter',sql.NChar,Customer_number)
                .query("SELECT * from CUSTOMER where Customer_number = @input_parameter");
                return products.recordsets;
            }
            catch(error){
                console.log(error);
            }
        }

    async function getCustomerFfc(Customer_number){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Customer_number)
            .query("SELECT * from FFC where Customer_number = @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function addCustomer(customer){
        try{
            let pool = await sql.connect(config);
            let insertProduct = await pool.request()
                .input('Customer_number',sql.NChar,customer.Customer_number)
                .input('Passport_number',sql.NChar,customer.Passport_number)
                .input('Email',sql.NChar,customer.Email)
                .input('Address',sql.NChar,customer.Address)
                .input('Country',sql.NChar,customer.Country)
                .input('Customer_phone',sql.NChar,customer.Customer_phone)
                .input('First_name',sql.NChar,customer.First_name)
                .input('Last_name',sql.NChar,customer.Last_name)
                .query("INSERT INTO [dbo].[CUSTOMER] VALUES ( @Customer_number,@Passport_number,@Email,@Address,@Country,@Customer_phone,@First_name,@Last_name)");
            return insertProduct.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function deleteCustomerFFC(Customer_number){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Customer_number)
            .query("DELETE FROM FFC WHERE Customer_number= @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function deleteCustomer(Customer_number){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Customer_number)
            .query("DELETE FROM CUSTOMER WHERE Customer_number= @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function updateCustomer(customer,Customer_number){
        try{
            let pool = await sql.connect(config);
            let updateProducts = await pool.request()
            .input('input_parameter',sql.NChar,Customer_number)
            .input('Email',sql.NChar,customer.Email)
            .input('Address',sql.NChar,customer.Address)
            .input('Country',sql.NChar,customer.Country)
            .input('Customer_phone',sql.NChar,customer.Customer_phone)
            .input('First_name',sql.NChar,customer.First_name)
            .input('Last_name',sql.NChar,customer.Last_name)
            .query("UPDATE CUSTOMER SET Email=@Email,Address=@Address,Country=@Country,Customer_phone=@Customer_phone,First_name=@First_name,Last_name=@Last_name WHERE Customer_number= @input_parameter");
            return updateProducts.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }
    
    async function getFlights(){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request().query("SELECT * from FLIGHT");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getFlight(Flight_number){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Flight_number)
            .query("SELECT * from FLIGHT where Flight_number = @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getFlightLegs(){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request().query("SELECT * from FLIGHT_LEG");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }
    
    async function getFlightLeg(Flight_number){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Flight_number)
            .query("SELECT * from FLIGHT_LEG where Flight_number = @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getAirports(){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request().query("SELECT * from AIRPORT");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }

    async function getAirport(Airport_code){
        try{
            let pool = await sql.connect(config);
            let products = await pool.request()
            .input('input_parameter',sql.NChar,Airport_code)
            .query("SELECT * from AIRPORT where Airport_code = @input_parameter");
            return products.recordsets;
        }
        catch(error){
            console.log(error);
        }
    }


    module.exports = {
        getCustomers : getCustomers,
        getFfc : getFfc,
        getCustomer : getCustomer,
        getCustomerFfc : getCustomerFfc,
        addCustomer : addCustomer,
        deleteCustomerFFC : deleteCustomerFFC,
        deleteCustomer : deleteCustomer,
        updateCustomer : updateCustomer,
        getFlights : getFlights,
        getFlight : getFlight,
        getFlightLegs : getFlightLegs,
        getFlightLeg : getFlightLeg,
        getAirports : getAirports,
        getAirport : getAirport

    }
 