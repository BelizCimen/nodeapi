var Db = require('./dboperations');
var Customer = require('./customer');
var Ffc = require('./ffc');
var Flight = require('./flight');
var FlightLeg = require('./flightLeg');
var Airport = require('./airport');
const dboperations = require('./dboperations');

var express = require('express');
var bodyParser = require('body-parser');
var cors = require('cors');
var app = express();
var router = express.Router();

app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());
app.use(cors());
app.use('/api',router);

router.use((request,response,next) => {
    console.log('middleware');
    next();
})

router.route('/customers').get((request,response) => {
    dboperations.getCustomers().then(result => { 
        response.json(result[0]);
    })
})

router.route('/customers/:Customer_number').get((request,response) => {
    dboperations.getCustomer(request.params.Customer_number).then(result => {  
        response.json(result[0]);
    })
})

router.route('/customers').post((request,response) => {

    let customer = {...request.body}

    dboperations.addCustomer(customer).then(result => { 
        response.status(201).json(result);
    })
})

router.route('/customers/:Customer_number').put((request,response) => {

    let customer = {...request.body}

    dboperations.updateCustomer(customer,request.params.Customer_number).then(result => { 
        response.status(200).json(result);
    })
})

router.route('/customers/:Customer_number').delete((request,response) => {
    dboperations.deleteCustomer(request.params.Customer_number).then(result => {  
        response.status(200).json(result[0]);
    })
})


router.route('/ffc').get((request,response) => {
    dboperations.getFfc().then(result => {
        response.json(result[0]);
    })
})

router.route('/ffc/:Customer_number').get((request,response) => {
    dboperations.getCustomerFfc(request.params.Customer_number).then(result => {  
        response.json(result[0]);
    })
})

router.route('/ffc/:Customer_number').delete((request,response) => {
    dboperations.deleteCustomerFFC(request.params.Customer_number).then(result => {  
        response.status(200).json(result[0]);
    })
})

router.route('/flights').get((request,response) => {
    dboperations.getFlights().then(result => { 
        response.json(result[0]);
    })
})

router.route('/flights/:Flight_number').get((request,response) => {
    dboperations.getFlight(request.params.Flight_number).then(result => {  
        response.json(result[0]);
    })
})

router.route('/flightLegs').get((request,response) => {
    dboperations.getFlightLegs().then(result => { 
        response.json(result[0]);
    })
})

router.route('/flightLegs/:Flight_number').get((request,response) => {
    dboperations.getFlightLeg(request.params.Flight_number).then(result => {  
        response.json(result[0]);
    })
})

router.route('/airports').get((request,response) => {
    dboperations.getAirports().then(result => { 
        response.json(result[0]);
    })
})

router.route('/airports/:Airport_code').get((request,response) => {
    dboperations.getAirport(request.params.Airport_code).then(result => {  
        response.json(result[0]);
    })
})


var port = process.env.PORT || 8090;
app.listen(port);
console.log('Airline API is running at ' + port);


