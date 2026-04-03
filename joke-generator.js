const fetch = require('node-fetch');

const getJoke = async () => {
    try {
        const response = await fetch('https://v2.jokeapi.dev/joke/Any');
        const data = await response.json();

        if (data.joke) {
            console.log('Joke:', data.joke);
        } else if (data.setup && data.delivery) {
            console.log('Setup:', data.setup);
            console.log('Delivery:', data.delivery);
        }
    } catch (error) {
        console.error('Error fetching joke:', error);
    }
};

getJoke();