'use strict';
console.log('Loading function');

let payment_lookup = {
	'Cash': 'Cash',
	'CASH': 'Cash',
	'Credit': 'Credit',
	'CREDIT': 'Credit',
	'No Charge': 'No Charge',
	'Dispute': 'Dispute'
};


exports.handler = (event, context, callback) => {
	let success = 0;
	let failure = 0;

	const output = event.records.map((record) => {
		try {
			console.log(record.recordId);
			const payload = (Buffer.from(record.data, 'base64')).toString('ascii');
			console.log('Decoded payload:', payload);

			let object = JSON.parse(payload);

			let result = {
				vendor_id: object.vendor_id,
				pickup_datetime: object.pickup_datetime,
				dropoff_datetime: object.dropoff_datetime,
				passenger_count: object.passenger_count,
				trip_distance: object.trip_distance,
				payment_type: payment_lookup[object.payment_type],
				fare_amount: object.fare_amount,
				surcharge: object.surcharge,
				tip_amount: object.tip_amount,
				tolls_amount: object.tolls_amount,
				total_amount: object.total_amount,
				pickup_location:{
					lat: parseFloat(object.pickup_latitude),
					lon: parseFloat(object.pickup_longitude)
				},
				dropoff_location:{
					lat: parseFloat(object.dropoff_latitude),
					lon: parseFloat(object.dropoff_longitude)
				}
			};
			success++;
			return {
				recordId: record.recordId,
				result: 'Ok',
				data: (Buffer.from(JSON.stringify(result))).toString('base64'),
			};
		} catch (e) {
			console.log('Error: ' + e + ' ' + e.stack);
			failure++;
			return {
				recordId: record.recordId,
				result: 'ProcessingFailed',
				data: record.data,
			};
		}
	});
	console.log(`Processing completed.  Successful records ${success}, Failed records ${failure}.`);
	callback(null, { records: output });
};