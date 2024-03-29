--Package Specification
CREATE OR REPLACE PACKAGE blackjack_pkg
AS
   --Types
   TYPE hand IS RECORD (
      deck_num                         card_deck.deck_num%TYPE
     ,card                             card_deck.card%TYPE
     ,suit                             card_deck.suit%TYPE
     ,value1                           card_deck.value1%TYPE
     ,value2                           card_deck.value2%TYPE
    );

   TYPE dealer_hand IS TABLE OF hand INDEX BY PLS_INTEGER;
   TYPE player_hand IS TABLE OF hand INDEX BY PLS_INTEGER;

   PROCEDURE play_blackjack (
      p_num_card_decks                    INTEGER DEFAULT 8
     ,p_num_of_players                    INTEGER DEFAULT 1
   );
END;
/

--Package Body
CREATE OR REPLACE PACKAGE BODY blackjack_pkg
AS
   PROCEDURE create_card_deck (p_deck_num INTEGER DEFAULT 1)
   AS
      --Types are similar to arrays in other languages
      TYPE card_type IS TABLE OF VARCHAR2(5) INDEX BY PLS_INTEGER;
      TYPE suit_type IS TABLE OF VARCHAR2(8) INDEX BY PLS_INTEGER;
      TYPE value_type IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

      card        card_type;
      suit        suit_type;
      value1      value_type;
      value2      value_type;
   BEGIN
      --Initialize card collection
      card(1) := '2';
      card(2) := '3';
      card(3) := '4';
      card(4) := '5';
      card(5) := '6';
      card(6) := '7';
      card(7) := '8';
      card(8) := '9';
      card(9) := '10';
      card(10) := 'Jack';
      card(11) := 'Queen';
      card(12) := 'King';
      card(13) := 'Ace';

      --Initialize suit collection
      suit(1) := 'Hearts';
      suit(2) := 'Diamonds';
      suit(3) := 'Spades';
      suit(4) := 'Clubs';

      --Initialize value collection
      value1(1) := 2;
      value1(2) := 3;
      value1(3) := 4;
      value1(4) := 5;
      value1(5) := 6;
      value1(6) := 7;
      value1(7) := 8;
      value1(8) := 9;
      value1(9) := 10;
      value1(10) := 10;
      value1(11) := 10;
      value1(12) := 10;
      value1(13) := 11;

      value2(1) := 0;
      value2(2) := 0;
      value2(3) := 0;
      value2(4) := 0;
      value2(5) := 0;
      value2(6) := 0;
      value2(7) := 0;
      value2(8) := 0;
      value2(9) := 0;
      value2(10) := 0;
      value2(11) := 0;
      value2(12) := 0;
      value2(13) := 1;

      EXECUTE IMMEDIATE 'TRUNCATE TABLE card_deck';

      --Loop through number of decks
      FOR v_deck_num IN 1 .. p_deck_num
      LOOP

         --Loop through number of cards
         FOR v_card_num IN 1 .. 13
         LOOP

            --Loop through number of suits
            FOR v_suit_num IN 1 .. 4
            LOOP
               INSERT INTO card_deck (
                  deck_num
                 ,card
                 ,suit
                 ,value1
                 ,value2
                 ,random_num
               ) VALUES (
                  v_deck_num
                 ,card(v_card_num)
                 ,suit(v_suit_num)
                 ,value1(v_card_num)
                 ,value2(v_card_num)
                 ,dbms_random.random()
               );
            END LOOP;
         END LOOP;
      END LOOP;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
   END;

   PROCEDURE shuffle_card_deck
   AS
   BEGIN
      UPDATE card_deck
         SET random_num = dbms_random.random();

      COMMIT;
   END;

   PROCEDURE play_blackjack (
      p_num_card_decks                    INTEGER DEFAULT 8
     ,p_num_of_players                    INTEGER DEFAULT 1
   )
   AS
      --Cursors
      CURSOR c_card_deck
      IS
      SELECT deck_num
            ,card
            ,suit
            ,value1
            ,value2
        FROM card_deck
      ORDER BY random_num;

      --Local Variables
      v_dealer_hand                       dealer_hand;
      v_player_hand                       player_hand;

      v_game_num                          INTEGER := 0;

      v_dealer_hand_card_cnt              INTEGER := 0;
      v_player_hand_card_cnt              INTEGER := 0;
      v_total_card_cnt                    INTEGER := 0;

      v_dealer_low_card_score             INTEGER := 0;
      v_dealer_mid_card_score             INTEGER := 0;
      v_dealer_high_card_score            INTEGER := 0;
      v_dealer_final_card_score           INTEGER := 0;

      v_player_low_card_score             INTEGER := 0;
      v_player_mid_card_score             INTEGER := 0;
      v_player_high_card_score            INTEGER := 0;
      v_player_final_card_score           INTEGER := 0;

      v_player_ace_cnt                    INTEGER := 0;
      v_dealer_ace_cnt                    INTEGER := 0;

      v_game_result_cd                    VARCHAR2(4) := NULL;
   BEGIN
   --   v_dealer_hand.COUNT;
   --   v_dealer_hand.EXISTS(i);
   --   v_dealer_hand.DELETE;
   --   v_dealer_hand.DELETE(i);
   --   v_dealer_hand(i).suit;
   --   v_dealer_hand(i).card;

      --Create a card desk
      blackjack_pkg.create_card_deck (p_num_card_decks);

      --Shuffle the card desk
      blackjack_pkg.shuffle_card_deck;

      --Opening the card_deck cursor so I can FETCH a card for the player and dealer.
      OPEN c_card_deck;

      --This is the main game loop; every loop is one hand of blackjack
      << game_loop >>
      LOOP
         --This statement keeps track of the number of cards used by the dealer and player for the previous game.
         v_total_card_cnt := v_total_card_cnt + v_dealer_hand_card_cnt + v_player_hand_card_cnt;

         --If 50% or more of the cards have been FETCHED from the v_card_desk CURSOR then quit the game.
         IF v_total_card_cnt / (p_num_card_decks * 52) >= 0.50 THEN
            EXIT game_loop;
         END IF;

         --Reset some loop variables
         v_game_num := v_game_num + 1;
         v_dealer_hand_card_cnt := 0;
         v_player_hand_card_cnt := 0;
         v_dealer_hand.DELETE;
         v_player_hand.DELETE;
         v_game_result_cd := NULL;
         v_player_low_card_score := 0;
         v_player_mid_card_score := 0;
         v_player_high_card_score := 0;
         v_player_final_card_score := 0;
         v_dealer_low_card_score := 0;
         v_dealer_mid_card_score := 0;
         v_dealer_high_card_score := 0;
         v_dealer_final_card_score := 0;

         --Deal 2 cards to the player, and deal 2 cards to the dealer
         << initial_deal >>
         FOR i in 1 .. 4
         LOOP
            --Player gets the 1st and 3rd card from c_card_deck  (IN (1,3) is the same as saying (i = 1 OR i = 3)
            IF i IN (1,3) THEN
               v_player_hand_card_cnt := v_player_hand_card_cnt + 1;

               FETCH c_card_deck INTO
                  v_player_hand(v_player_hand_card_cnt).deck_num
                 ,v_player_hand(v_player_hand_card_cnt).card
                 ,v_player_hand(v_player_hand_card_cnt).suit
                 ,v_player_hand(v_player_hand_card_cnt).value1
                 ,v_player_hand(v_player_hand_card_cnt).value2;
               EXIT WHEN c_card_deck%NOTFOUND;
            --Dealer gets the 2nd and 4th card from c_card_desk
            ELSE
               v_dealer_hand_card_cnt := v_dealer_hand_card_cnt + 1;

               FETCH c_card_deck INTO
                  v_dealer_hand(v_dealer_hand_card_cnt).deck_num
                 ,v_dealer_hand(v_dealer_hand_card_cnt).card
                 ,v_dealer_hand(v_dealer_hand_card_cnt).suit
                 ,v_dealer_hand(v_dealer_hand_card_cnt).value1
                 ,v_dealer_hand(v_dealer_hand_card_cnt).value2;
               EXIT WHEN c_card_deck%NOTFOUND;
            END IF;
         END LOOP;

         --Player decides to keep hitting or stay based on if their score is less than 17
         << player_loop >>
         LOOP
            --Reset player score
            v_player_ace_cnt := 0;
            v_player_low_card_score := 0;
            v_player_mid_card_score := 0;
            v_player_high_card_score := 0;

            --Calculates the best and worst case score for the players hand at this point
            << calc_player_hand_score >>
            FOR i IN 1 .. v_player_hand.COUNT
            LOOP
               IF v_player_hand(i).card = 'Ace' THEN
                  v_player_ace_cnt := v_player_ace_cnt + 1;
               END IF;

               IF v_player_ace_cnt = 1 AND v_player_hand(i).card = 'Ace' THEN
                  v_player_low_card_score := v_player_hand(i).value2 + v_player_low_card_score;
                  v_player_mid_card_score := v_player_hand(i).value2 + v_player_mid_card_score;
                  v_player_high_card_score := v_player_hand(i).value1 + v_player_high_card_score;
               ELSIF v_player_ace_cnt > 1 AND v_player_hand(i).card = 'Ace' THEN
                  v_player_low_card_score := v_player_hand(i).value2 + v_player_low_card_score;
                  v_player_mid_card_score := v_player_hand(i).value1 + v_player_mid_card_score;
                  v_player_high_card_score := v_player_hand(i).value1 + v_player_high_card_score;
               ELSE
                  v_player_low_card_score := v_player_hand(i).value1 + v_player_low_card_score;
                  v_player_mid_card_score := v_player_hand(i).value1 + v_player_mid_card_score;
                  v_player_high_card_score := v_player_hand(i).value1 + v_player_high_card_score;
               END IF;
            END LOOP;

            IF v_player_high_card_score <= 21 THEN
               v_player_final_card_score := v_player_high_card_score;
            ELSIF v_player_mid_card_score <= 21 THEN
               v_player_final_card_score := v_player_mid_card_score;
            ELSE
               v_player_final_card_score := v_player_low_card_score;
            END IF;

            --If the players final score is greater than or equal to 17 the exit the player loop so the dealer can play.
            IF v_player_final_card_score >= 17 THEN
               EXIT player_loop;
            ELSE
               v_player_hand_card_cnt := v_player_hand_card_cnt + 1;

               FETCH c_card_deck INTO
                  v_player_hand(v_player_hand_card_cnt).deck_num
                 ,v_player_hand(v_player_hand_card_cnt).card
                 ,v_player_hand(v_player_hand_card_cnt).suit
                 ,v_player_hand(v_player_hand_card_cnt).value1
                 ,v_player_hand(v_player_hand_card_cnt).value2;
               EXIT WHEN c_card_deck%NOTFOUND;
            END IF;
         END LOOP;  --player_loop

         --Player busted so player looser
         IF v_player_final_card_score > 21 THEN
            v_game_result_cd := 'Lose';
         ELSE
             --Dealer decides to keep hitting or stay based on if their score is less than 17
            << dealer_loop >>
            LOOP
               v_dealer_ace_cnt := 0;
               v_dealer_low_card_score := 0;
               v_dealer_mid_card_score := 0;
               v_dealer_high_card_score := 0;

               FOR i IN 1 .. v_dealer_hand.COUNT
               LOOP
                  IF v_dealer_hand(i).card = 'Ace' THEN
                     v_dealer_ace_cnt := v_dealer_ace_cnt + 1;
                  END IF;

                  IF v_dealer_ace_cnt = 1 AND v_dealer_hand(i).card = 'Ace' THEN
                     v_dealer_low_card_score := v_dealer_hand(i).value2 + v_dealer_low_card_score;
                     v_dealer_mid_card_score := v_dealer_hand(i).value2 + v_dealer_mid_card_score;
                     v_dealer_high_card_score := v_dealer_hand(i).value1 + v_dealer_high_card_score;
                  ELSIF v_dealer_ace_cnt > 1 AND v_dealer_hand(i).card = 'Ace' THEN
                     v_dealer_low_card_score := v_dealer_hand(i).value2 + v_dealer_low_card_score;
                     v_dealer_mid_card_score := v_dealer_hand(i).value1 + v_dealer_mid_card_score;
                     v_dealer_high_card_score := v_dealer_hand(i).value1 + v_dealer_high_card_score;
                  ELSE
                     v_dealer_low_card_score := v_dealer_hand(i).value1 + v_dealer_low_card_score;
                     v_dealer_mid_card_score := v_dealer_hand(i).value1 + v_dealer_mid_card_score;
                     v_dealer_high_card_score := v_dealer_hand(i).value1 + v_dealer_high_card_score;
                  END IF;
               END LOOP;

               IF v_dealer_high_card_score <= 21 THEN
                  v_dealer_final_card_score := v_dealer_high_card_score;
               ELSIF v_dealer_mid_card_score <= 21 THEN
                  v_dealer_final_card_score := v_dealer_mid_card_score;
               ELSE
                  v_dealer_final_card_score := v_dealer_low_card_score;
               END IF;

               IF v_dealer_final_card_score >= 17 THEN
                  EXIT dealer_loop;
               ELSE
                  v_dealer_hand_card_cnt := v_dealer_hand_card_cnt + 1;

                  FETCH c_card_deck INTO
                     v_dealer_hand(v_dealer_hand_card_cnt).deck_num
                    ,v_dealer_hand(v_dealer_hand_card_cnt).card
                    ,v_dealer_hand(v_dealer_hand_card_cnt).suit
                    ,v_dealer_hand(v_dealer_hand_card_cnt).value1
                    ,v_dealer_hand(v_dealer_hand_card_cnt).value2;
                  EXIT WHEN c_card_deck%NOTFOUND;
               END IF;
            END LOOP;  --dealer_loop

            --Dealer busts OR player wins
            IF v_dealer_final_card_score > 21 OR v_player_final_card_score > v_dealer_final_card_score THEN
               v_game_result_cd := 'Win';
            --Tie score
            ELSIF v_dealer_final_card_score = v_player_final_card_score THEN
               v_game_result_cd := 'Push';
            --Dealer wins
            ELSE
               v_game_result_cd := 'Lose';
            END IF;
         END IF;

         --DBMS_OUTPUT player cards
         FOR i IN 1 .. v_player_hand.COUNT
         LOOP
            dbms_output.put_line (
               'Player (' || v_game_num || ') : ' ||
               v_player_hand(i).deck_num || '|' ||
               v_player_hand(i).card || '|' ||
               v_player_hand(i).suit || '|' ||
               v_player_hand(i).value1 || '|' ||
               v_player_hand(i).value2
            );
         END LOOP;

         --DBMS_OUTPUT dealer cards
         FOR i IN 1 .. v_dealer_hand.COUNT
         LOOP
            dbms_output.put_line (
               'Dealer (' || v_game_num || ') : ' ||
               v_dealer_hand(i).deck_num || '|' ||
               v_dealer_hand(i).card || '|' ||
               v_dealer_hand(i).suit || '|' ||
               v_dealer_hand(i).value1 || '|' ||
               v_dealer_hand(i).value2
            );
         END LOOP;

         IF v_player_hand_card_cnt = 2 AND v_player_high_card_score = 21 AND v_game_result_cd = 'Win' THEN
            dbms_output.put_line (' ');
            dbms_output.put_line ('    !!! BLACKJACK !!!    ');
            dbms_output.put_line (' ');
         END IF;

         dbms_output.put_line ('Player card score: ' || v_player_low_card_score || '/' || v_player_mid_card_score || '/' || v_player_high_card_score || ' (' || v_player_final_card_score || ')');
         dbms_output.put_line ('Dealer card score: ' || v_dealer_low_card_score || '/' || v_dealer_mid_card_score || '/' || v_dealer_high_card_score || ' (' || v_dealer_final_card_score || ')');
         dbms_output.put_line ('           Result: ' || v_game_result_cd);
         dbms_output.put_line (' ');

      END LOOP;  --game_loop

      CLOSE c_card_deck;
   END;
END;
/

SET SERVEROUTPUT ON;

BEGIN
   blackjack_pkg.play_blackjack (100, 1);
END;
/
