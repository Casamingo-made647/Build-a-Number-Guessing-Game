#!/bin/bash

PSQL="psql --no-psqlrc --quiet --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r username
username_sql=$(printf "%s" "$username" | sed "s/'/''/g")

user_id=$($PSQL "SELECT user_id FROM users WHERE username='$username_sql';")
if [[ -z $user_id ]]; then
  user_id=$($PSQL "INSERT INTO users(username) VALUES('$username_sql') RETURNING user_id;")
  echo "Welcome, $username! It looks like this is your first time here."
else
  games_played=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$user_id;")
  best_game=$($PSQL "SELECT MIN(number_guesses) FROM games WHERE user_id=$user_id;")
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0
echo "Guess the secret number between 1 and 1000:"

while true; do
  read -r guess
  number_of_guesses=$((number_of_guesses + 1))

  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_number=$((10#$guess))
  fi

  if (( guess_number < secret_number )); then
    echo "It's higher than that, guess again:"
  elif (( guess_number > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    $PSQL "INSERT INTO games(user_id, number_guesses) VALUES($user_id, $number_of_guesses);" > /dev/null
    echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
    break
  fi
done
