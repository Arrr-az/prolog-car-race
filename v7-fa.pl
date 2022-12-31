%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Servidor em prolog

% Módulos:
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/json)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_dirindex)).
%DEBUG:
:- use_module(library(http/http_error)).
:- debug.

% GET
:- http_handler(
    root(action), % Alias /action
    action,       % Predicado 'action'
    []).

:- http_handler(root(.), http_reply_from_files('.', []), [prefix]).

:- json_object
    controles(forward:integer, reverse: integer, left:integer, right:integer).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]).

stop_server(Port) :-
    http_stop_server(Port, []).

action(Request) :-
    http_parameters(Request,
                    % sensores do carro:
                    [ x(X, [float]),
                      y(Y, [float]),
                      angle(ANGLE, [float]),
                      s1(S1, [float]),
                      s2(S2, [float]),
                      s3(S3, [float]),
                      s4(S4, [float]),
                      s5(S5, [float])
                    ]),
    SENSORES = [X,Y,ANGLE,S1,S2,S3,S4,S5],
    obter_controles(SENSORES, CONTROLES),
    acao(SENSORES, Acao, Pontuacao),
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT],
    prolog_to_json( controles(FORWARD, REVERSE, LEFT, RIGHT), JOut ),
    reply_json( JOut ).

start :- format('~n~n--========================================--~n~n'),
         start_server(8080),
         format('~n~n--========================================--~n~n').
:- initialization start.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*MÓDULO 1*/

/*R1: RECUANDO AO ENCONTRAR OBSTÁCULOS INTRANSPONÍVEIS À FRENTE, IMPORTANTE PARA MINIMIZAR BUGS*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [0,1,0,0], Pontuacao) :-
    S2 > 0.6,
    S3 > 0.6,
    S4 > 0.6,
    Pontuacao = 0.1.

/*R2: RECUANDO AO SE VER 'GRUDADO' EM UM OBSTÁCULO À FRENTE, IMPORTANTE PARA MINIMIZAR BUGS*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [0,1,0,0], Pontuacao) :-
    (S2 > 0.8, S3 > 0.8);
    (S4 > 0.8, S3 > 0.8),
    Pontuacao = 0.1.

/*R3: AJUSTANDO ÂNGULO: SENTIDO HORÁRIO*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0], Pontuacao) :-
    ANGLE < -0.8,
    Pontuacao = 0.2.

/*R4: AJUSTANDO ÂNGULO: SENTIDO ANTI-HORÁRIO*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1], Pontuacao) :-
    ANGLE > 0.8,
    Pontuacao = 0.2.

/*R5: NÃO BATER NA PAREDE DA DIREITA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0], Pontuacao) :-
    S5 > 0.8,
    X > 145,
    Pontuacao = 0.3.

/*R6: NÃO BATER NA PAREDE DA ESQUERDA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1], Pontuacao) :-
    S1 > 0.8,
    X < 50,
    Pontuacao = 0.3.

/*R7: SE LIVRAR DE UM CARRO MUITO PRÓXIMO À DIREITA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0], Pontuacao) :-
    S5 > 0.7,
    X > 50,
    X < 145,
    Pontuacao = 0.4.

/*R8: SE LIVRAR DE UM CARRO MUITO PRÓXIMO À ESQUERDA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1], Pontuacao) :-
    S1 > 0.7,
    X > 50,
    X < 145,
    Pontuacao = 0.4.

/*R9: FRENTE, ENQUANTO O ÂNGULO ESTIVER PRÓXIMO DE 0 E NÃO HOUVER NENHUM OBSTÁCULO CRÍTICO À FRENTE*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,0], Pontuacao) :-
    S2 < 0.7,
    S3 < 0.5,
    S4 < 0.7,
    ANGLE > -0.5,
    ANGLE < 0.5,
    Pontuacao = 0.5.

/*R10: FRENTE-ESQUERDA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0], Pontuacao) :-
    S4+S5 > S1+S2+0.1,
    Pontuacao = 0.6.

/*R11: FRENTE-DIREITA*/
acao([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1], Pontuacao) :-
    S1+S2 > S4+S5+0.1,
    Pontuacao = 0.6.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*MÓDULO 2*/
/*Verifica se "Elem" não é membro da lista*/

% base:
naoMembro([], _) :- !.
% passo:
naoMembro([A|R], Elem) :- A \= Elem, naoMembro(R, Elem).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*MÓDULO 3*/
/*Regra que reuna todas as ações que podem ser aplicadas naqueles sensores do momento*/

% passo:
todasAcoes([X,Y,ANGLE,S1,S2,S3,S4,S5], AcoesAux, TodasAcoes) :-
    acao([X,Y,ANGLE,S1,S2,S3,S4,S5], Acao, Pontuacao),
    naoMembro(AcoesAux, [Acao, Pontuacao]),
    todasAcoes([X,Y,ANGLE,S1,S2,S3,S4,S5], [ [Acao, Pontuacao] | AcoesAux ], TodasAcoes),
    !.
% base:
todasAcoes(_, Acoes, Acoes) :- !.
% para facilitar a chamada do predicado:
todasAcoes([X,Y,ANGLE,S1,S2,S3,S4,S5], Acoes) :-
    todasAcoes([X,Y,ANGLE,S1,S2,S3,S4,S5], [], Acoes).

/*
O resultado disso é a variável 'Acoes' que é uma lista de pares ordenados do tipo [Acao, Pontuacao] contendo 2 itens:
1- Acao: comando do tipo [0,0,0,0], [0,1,1,0], etc. que o carrinho pode executar a partir dos SENSORES que recebeu naquele momento
2- Pontuacao: pontuação relativa àquela ação
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*MÓDULO 4*/
/*Encontra a menor pontuação em uma lista de pares ordenados do tipo [Acao, Pontuacao]*/

% base:
menorPontuacaoAux([], _, AcaoAtualAux, AcaoAtualAux) :- !.
% passo 1 (quando a pontuação da primeira ação da lista (A) é menor que o PontuacaoAtual)
menorPontuacaoAux([AcaoAtual|Resto], PontuacaoAtual, _, AcaoAtualAux) :-
    [_, Pontuacao] = AcaoAtual,
    Pontuacao < PontuacaoAtual,
    menorPontuacaoAux(Resto, Pontuacao, AcaoAtual, AcaoAtualAux).
% passo 2 (quando o PontuacaoAtual é menor que o primeiro da lista):
menorPontuacaoAux([_|Resto], PontuacaoAtual, MelhorAcao, AcaoAtualAux) :-
    menorPontuacaoAux(Resto, PontuacaoAtual, MelhorAcao, AcaoAtualAux).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*MÓDULO 5*/
/*
A variável 'Menor' se refere ao menor par ordenado do tipo [Acao, Pontuacao]. Que nesse caso, tem suas variáveis
internas referenciadas como 'CONTROLES' e 'MenorPontuacao'
*/

melhorAcao([X,Y,ANGLE,S1,S2,S3,S4,S5], CONTROLES, MenorPontuacao) :-
    todasAcoes([X,Y,ANGLE,S1,S2,S3,S4,S5], Acoes),
    menorPontuacaoAux(Acoes, 9999, [], Menor),
    [CONTROLES, MenorPontuacao] = Menor,
    !.
% caso não encontre, retorna lista vazia e 9999 de pontuação.
melhorAcao(_, [0,0,0,0], 9999).

obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], CONTROLES) :-
    melhorAcao([X,Y,ANGLE,S1,S2,S3,S4,S5], CONTROLES, MenorPontuacao).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%