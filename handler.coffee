module.exports.addEmail = (event, context, callback) =>
	response =
		statusCode: 201
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify
			message: 'Go Serverless v1.0! Your function executed successfully!'
			input: event

	callback(null, response);

module.exports.confirmEmail = (event, context, callback) =>
	response =
		statusCode: 200
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify
			message: 'Go Serverless v1.0! Your function executed successfully!'
			input: event

	callback(null, response);

module.exports.deleteEmail = (event, context, callback) =>
	response =
		statusCode: 204
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify
			message: 'Go Serverless v1.0! Your function executed successfully!'
			input: event

	callback(null, response);
