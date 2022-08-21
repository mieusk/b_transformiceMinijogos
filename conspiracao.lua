---------------------------------------------------------
-- e aí, parsa
-- não sou o chico xavier da programação
-- então é claro q o script vai estar cheio de gambiarras
-- tem alguma crítica p/ dar? fale à vontade
-- autoria de preuclides#3383 rs
-- um modelo de "conspiração" no transformice
-- ideia de um joguinho de celular semelhante a esse
-- créditos: {
--    Sklag#2552 pelo script de Degradê,
--    Ninguem#0095 por me deixar roubar o mapa do unotfm,
--    Alguns snippets foram furtados do stackoverflow </3
--  }
-- 10/08/2022
--[[utilidade: 

ui.addTextArea(id, texto, player, x, y, largura, altura, corFundo, corBorda, binarioOpacidade, binarioPos)
function eventTextAreaCallback(id, p, name) end

]]

--declarando as funções globais usadas no script para + otimização
--coroutines
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield

--strings
local string_sub = string.sub
local string_len = string.len

--tables
local table_unpack = table.unpack
local table_insert = table.insert

--uis
local ui_addTextArea = ui.addTextArea
local ui_removeTextArea = ui.removeTextArea

--execs
local tfm_exec_addImage = tfm.exec.addImage
local tfm_exec_removeImage = tfm.exec.removeImage
local tfm_exec_newGame = tfm.exec.newGame
local tfm_exec_respawnPlayer = tfm.exec.respawnPlayer
local tfm_exec_setPlayerScore = tfm.exec.setPlayerScore

--outros
local math_random = math.random
local math_randomseed = math.randomseed
local os_time = os.time
local system_bindKeyboard = system.bindKeyboard
--não colocaremos o tfm.get.room.playerList pois este é uma table e não uma função
--ps. é desnecessário adicionar funções globais nesta lista que são usadas só algumas vezes
--isso só é útil qnd ela é usada 200 ou + vezes no script

--randomização desnecessariamente grande, mas fazer o que se o resultado assim é melhor...
math_randomseed(math_random(os_time()+math_random()^286637850%64666/math_random()^math_random(os_time(), os_time()+1099511627776)*math_random(32, 64), 60525076796/478324)+1000000000)


--desativa shaman, inicio de jogo, tempo, morte automática e ponto automático
do local disable = {'AutoShaman', 'AutoNewGame', 'AutoTimeLeft', 'AfkDeath', 'AutoScore'}
  for i=1, #disable do
    tfm.exec['disable'..disable[i]]()
  end
end

--lista de administradores
local administradores = {['Preuclides#3383'] = true} --se é administrador

--lista de jogadores e sua pontuação
local jogadoresGlobais = {['Preuclides#3383'] = 0} --jogadores e seu número de vitórias

--tabelas do jogo
local jogadoresNaSala = {} --lista de jogadores na sala

local jogadoresNoJogo = {} --{nick, papel} lista de jogadores na cadeira
local papeisNoJogo = {1, 0, 0, 1, 1, 1} --0 é espião, 1 é sociedade
local jogadoresTotais = 0 --total de jogadores nas cadeiras

--cores usadas no jogo para as textareas
local coresPadrao = {brancoDeTexto = 'FDFDFE',
    brancoMaisEscuro = 'EDEDEE',
    corDeEspaco = 'BABD2F',
    textAreaFundo = '000001',
    textAreaBorda = '554444',
    espiao = 'FF0C40', --cor vermelho para espião
    sociedade = '10FF54',
    lider = '0950FF',
    missaoNumero = 'FFBF00',
    missaoEspecialTitulo = 'FFAAFF',
    missaoEspecial = 'ED67EA'}

--tempo total percorrido no modo
local tempoPercorrido = 0

--elementos da missão
local liderDaMissao = 'Inconnu#0000' --quem estará escolhendo os agentes
local liderGenero --nenhum, feminino e masculino
local missaoSelecionada = 1 --número do título da missão selecionada
local missaoAtual = 1 --número da missão atual
local numeroDeAgentesNaMissao = 0 --quantos agentes terão na missão atual
local missoesSabotadas = 0 --número de missões sabotadas (se 3, jogo acaba)
local missoesSucedidas = 0 --numero de missões bem-sucedidas (se 3, jogo acaba)

--agentes da missão atual
local agentesAtuais = {} --agentes escolhidos para a missão atual
local agentesForamAprovados = false --se agentes foram aprovados
local sequenciaPossivelDeAgentes = {{2, 3, 2, 2, 3}, {2, 2, 2, 3, 3}, {2, 3, 2, 3, 2}} --sequência de número de agente nas missões
local sequenciaDaPartida = sequenciaPossivelDeAgentes[math_random(#sequenciaPossivelDeAgentes)] --a sequência de agentes na partida atual

--mensagens específicas pra exibir
local mensagemAleatoria = {'Allah te guiará nessa.', 'Adeus, Buda.', 'Seu objetivo está tão perto.', 'Seja compassivo.', 'AAAAAA ele me arranhou.', 'Em nome do pai.', 'Obliviscitur tenebris.', 'Ac tenebras.', 'Invenire astrologus.', 'Memento mori.', 'Et non moriatur.', 'Não esqueça ao que você está aqui.', 'Maloso vobiscum et cum spiritum.', 'Anseio por paz em meu coração.', 'Você entendeu algo?', 'Estamos de olho.', 'Você está sendo observado.', 'A sociedade não perdoa.', 'Você está estranhamente de bom humor.', 'Este sorriso é suspeito.', 'Tem algo em mente?', 'Temos olhos nas paredes...', 'É você?', 'Como você sabia?', 'Mi vitae, felis, bibendum.', 'Maior sum quam liber tuus.', 'Julgue!', 'Será que é uma boa?'}
local pronomes = {[0] = 'Elu', [1] = 'Ela', [2] = 'Ele'} --mostra elu, ela ou ele nas textareas

--título das missões
local listaDeMissoes = {
    --1-3
    {'Achatar a Terra', 'Que a Terra é plana todo o globo sabe. Mas a sociedade viu o capitão do exército americano comentando sobre a contrução de equipamentos de terraformação para curvar a Terra localizados no parque de Tallahassee. Sugeriu-se que '..numeroDeAgentesNaMissao..' agentes da sociedade viajassem para os parques da cidade, onde o congressista Manchuriano e os agentes, acompanhados por quatro carros de palhaços chamando a atenção do público, destruiriam a máquina e achataria a Terra novamente.'}, 
    {'Fazer chapéus de alumínio', 'Abstendo-se ao manejo mental das micro-ondas, a fábrica de chapéus alumínio inspirou-se em folhas de duas camadas, quatro camadas se separadas umas das outras. A ponta encolhe e, portanto, torna-se cada vez mais pequena. Guarde para você. Mantenha-o fresco. Imite em um. A repetição é um programa de aula gratuito. Respiração profunda. Você dá os sinais de porta logo após dar as instruções. Defina os controles no modo de alto impacto para que apenas os membros da sociedade protejam-se do controle mental.'}, 
    {'Gravar pouso falso na Lua', 'A diretora da sociedade manda uma carta: "Cara sociedade, uma nave espacial apareceu em Hollywood onde o menino está e começou a filmá-lo pulando. Dentro do navio está o capitão do exército japonês com máscara de macaco, pedindo pela entrega do material do pouso lunar falso. Sombras apareceram me chamando para a gravação lunar. Livre como macaco, haha. Quero que vocês lidem com isto. Atenciosamente, Diretora Hello Kitty". O membro '..liderDaMissao..' vai nos liderar nessa.'}, 
    --4-6
    {'Visitar família da Elizabeth II', 'Uma carta escrita em nome da reptiliana Elizabeth II para um de seus favoritos marítimos contava sobre o desejo dos répteis em aliar-se à nossa sociedade. A britânica Elizabeth II provou ser uma marca igualmente evocativa de monarca, e não um gosto resistente ao ridículo. À medida que o país se apressava de contar séculos de sagas e dinastias, Elizabeth II, a imortal, retratou os leitores com o registro de suas aventuras nos pântamos. Devemos visitar o pântano secreto da rainha para firmar a aliança.'}, 
    {'Achar filhos do Conde Drácula', 'O gato sugeriu fincar uma estaca no coração do vampiro para que ele se dissipe e sejamos mais fortes. Ah! Bobeira... Nadaremos em ouro com a aliança dos vampiros. Justiça, Romênia, preferência. Desde quando você quer justiça para os cristãos? Peter (memória falsa) sugeriu que um vampiro de aparência humana se tornasse humano (ah hah, perfeito porque essa pessoa provavelmente ficaria melhor). O gato lamentavelmente esfaqueou o vampiro romeniano e rasgou sua linda lingerie.'}, 
    {'Começar um desastre "natural"', 'O cientista Peter, assistente na base de aquecimento da ionosfera, olha para Mara Chung, agarra seu namorado Marco em algum lugar na multidão, entra no corredor e bate a porta do centro de pesquisa. Ele concluiu seu pensamento: Este monte de fracotes não percebe o que nós representamos. Histeria em massa. Moeda de piada para as autoridades da cidade da próxima semana. Aqueça a ionosfera na temperatura máxima com a ajuda de '..numeroDeAgentesNaMissao..' agentes para destruir este lugar.'}, 
    --7-9
    {'Inspec. bunker apocalíptico', 'Na Groenlândia comemos peixes capturados há apenas alguns meses, os ursos nos trazem comida depois de procurar mísseis nucleares no subsolo, há um enorme bunker, seu verde reluzente na neve, absorvedores de eco varreram a escuridão, usamos luvas brancas aqui, alguns pequenos manequins sendo substituídos, um soldado avança, Pelé voa como um velho urso polar, somos solenes, elogios para o diretor angolano David do bunker. Pede para inspecionar.'}, 
    {'Quebrar mercado de ações', 'Propomos a queda de 99% de todas as ações, reduzindo o valor das ações para o valor básico até que a reconstrução possa começar. Em última análise, as ações voltarão como sangue nas veias. A era da oferta e da demanda se aproxima. Somente a natureza fornece mensagens dessa urgência. O dinheiro se torna primitivo, perverso, cru e apaixonado ao longo de décadas. Maluco acima. Digno de rancor abaixo. São '..numeroDeAgentesNaMissao..' agentes que derrubarão as ações e acabarão com o dinheiro desprezível que controla nossas vidas.'}, 
    {'Sabotar alianças internacionais', 'A Santíssima Trindade que une os países deve ser derrubada. Manipularemos o governo japonês para atacar ativistas japoneses. Manifestantes não conseguem silenciar os defensores do sistema. A cobra da sociedade envenenará aqueles que se oporem a ela. A ação das forças sombrias de Roma, assustando as feministas, conspira por motivos ecniilistas legítimos contra fatos políticos. Os opressores chineses globais dizem "adeus Buda". Somento a sociedade pode apagar as uniões globais.'}, 
    --10-12
    {'Sabotar organizações rivais', 'Uma época em que movimentos desonestos usados em tecnologias gatinas (propriedade dos gatos) levam, espontaneamente, a uma evolução evolutivos de um robô móvel biológico secreto capaz de se infiltrar dentro de cada organismo para controlar, escanear, monitorar, visualizar e registrar as atividades humanas dia e noite. A sociedade usará os dispositivos imponentes para vigilância e mapeamento celular que colocam em risco a humanidade para retalhar as ações dos inimigos.'}, 
    {'Encontrar o homem de Marte', 'Marco estava sentado nu no chão enquanto conversava com o homem de Marte, salvador de mundos perigosos colonizados. Marco (memória real) lhe oferecia um gato em troca da salvação da Terra (que é plana). Bigode, máscara e vestido são as roupas naturais do homem de Marte. Balões coloridos voavam pela estrada marciana. Eram eles: os palhaços e o homem manchuriano, que procuravam pela companhia de '..numeroDeAgentesNaMissao..' agentes para visitá-lo. Precisamos de bigodes, máscaras e vestidos para nos juntar a eles.'}, 
    {'Eleger candidato manchuriano', 'Mara Chong organizou uma audiência ao candidato manchuriano. A diretora Hello Kitty buscava o consulado chinês. O congressista era o modelo de palco. A cobra produziu o filme de campanha como uma paródia de espionagem. Mara Chong repreendeu a cobra pela ironia. Só falta os agentes distribuirem o show de música & comédia que mostra por que a legislação da Manchúria aprovou o capturador de graves, dedicou as baleias a Deus e transformou os manchurianos em súditos benevolentes 15 minutos depois.'}, 
    --13-15
    {'<font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Prever o futuro com tarot</b></font>', '\n\n<font size="12">Parece que essa <font color="#'..coresPadrao.missaoEspecial..'"><b>missão</b></font> é <font color="#'..coresPadrao.missaoEspecial..'"><b>especial</b></font>. Madame Lulu joga suas cartas na mesa: duas letras que existem no nome de um dos espiões são reveladas. Apenas os agentes da missão veem as letras. Este futuro será profíquo?'}, 
    {'<font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Conversar com a Bruxa Branca</b></font>', '\n\n<font size="12"><font color="#'..coresPadrao.missaoEspecial..'"><b>Missão especial</b></font> da sede da sociedade secreta! Encontre a Bruxa Branca, ela desfrutará seus poderes absolutos para te metamorfosear em sociedade ou espião, de acordo com seus desejos. Só um agente da missão pode se comunicar com ela.'}, 
    {'<font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Conversar com a Bruxa Negra</b></font>', '\n\n<font size="12">Anormalidade: <font color="#'..coresPadrao.missaoEspecial..'"><b>missão especial</b></font>. A Bruxa Negra jogará uma praga na Missão #5, fazendo com que ela seja bem-sucedida ou sabotada de modo automático, sem importar quais são os agentes da missão. Só um agente pode conversar com a Bruxa Negra.'}
  }

--modos e suas propriedades
local listaDeModos = { 

  { --pegar as cadeiras 1
    tipoDoModo = 'cadeira', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = true, --se esse é o modo ativo ou não
    textAreaDeTempo = 7, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 0 --duração do modo
    },

  { --parte em que mostra se vc é espião ou sociedade 2
    tipoDoModo = 'inciar', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 8, --número da textArea de tempo
    textAreasDoModo = 11, --número da textArea importante
    duracaoDoModo = 10 --duração do modo
    },

   { --exibição da missão que iniciará 3
    tipoDoModo = 'exibir', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 8, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 16 --duração do modo
    },

  { --seleção de agentes pelo líder 4
    tipoDoModo = 'selecionar', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 8, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 45 --duração do modo
    },

  { --aprovação da missão pela população 5
    tipoDoModo = 'aprovar', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 8, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 0 --duração do modo
    },

   { --durante a execução da missão 6
    tipoDoModo = 'agir', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 8, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 0 --duração do modo
    },

  { --final de tudo 7
    tipoDoModo = 'encerrar', --o ID do modo
    primeiraVez = true, --se é a primeira vez que tá sendo executado
    modoAtual = false, --se esse é o modo ativo ou não
    textAreaDeTempo = 9, --número da textArea de tempo
    textAreasDoModo = nil, --número da textArea importante
    duracaoDoModo = 0 --duração do modo
    }
}

--ajustando algumas coisas, adiciona index na tabela
setmetatable(jogadoresNoJogo, {__index = function()
  return {'</b><font size="11">[ espaço ]', 2}
end})

--text areas gerais
local textAreas = function(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra)
  local numeroExtra = numeroExtra or 1
  local textoAuxiliar = textoAuxiliar or ''
  for i=numeroDaTextArea, numeroDaTextArea do
    return ({
      --1-6 - lista de cadeiras
      {1, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[1][1], jogadorAlvo, 000, 100, 100, 20, nil, nil, 0, false},
      {2, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[2][1], jogadorAlvo, 130, 100, 120, 20, nil, nil, 0, false},
      {3, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[3][1], jogadorAlvo, 270, 100, 120, 20, nil, nil, 0, false},
      {4, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[4][1], jogadorAlvo, 410, 100, 120, 20, nil, nil, 0, false},
      {5, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[5][1], jogadorAlvo, 550, 100, 120, 20, nil, nil, 0, false},
      {6, "<p align='center'><font size='10' color='#"..textoAuxiliar.."'><b>"..jogadoresNoJogo[6][1], jogadorAlvo, 700, 100, 100, 20, nil, nil, 0, false},
      --7 - do modo 'cadeira', text areas de jogadores que faltam
      {7, '<p align="center"><font size="12" color="#'..coresPadrao.brancoMaisEscuro..'">Faltam <font size="12" color="#'..coresPadrao.missaoNumero..'">'..6-jogadoresTotais..'</font> jogadores</font></p>', nil, 320, 20, 160, 25, tonumber('0x'..coresPadrao.textAreaFundo), tonumber('0x'..coresPadrao.textAreaBorda), 0.85},
      --8 - contagem de tempo na maioria do listaDeModos
      {8, '<p align="center"><font size="16" color="#'..coresPadrao.missaoNumero..'">'..numeroExtra-tempoPercorrido, nil, 375, 20, 50, 20, 0x000001, 0x443333, 0.85},
      --9 do modo 'encerrar', mostra "fim de jogo"
      {9, '<p align="center"><font size="16" color="#C2C2DA">Fim de jogo', nil, 375, 20, 50, 20, nil, nil, 0.5},
      --10 reservado para alguma coisa
      {10,'\n\n\n\n\n\n\n\n\n\n<p align="center"><font color="#FFFFFF" size="24" face="lucida console"><b> <font color="#FF0000">[ ERRO ]</font> O jogo quebrou!\nRecarregue o script\nou mude de sala para corrigir.</b>\n\n\n\n<font size="18">Chame no Discord: flamma#0050 caso o erro persista.</font></font>', nil, 0, 0, 800, 400, tonumber('0x'..coresPadrao.brancoMaisEscuro), tonumber('0x'..coresPadrao.brancoMaisEscuro), 0, false},
      --11 do modo 'iniciar', mostra se é espião ou sociedade; do modo 'exibir', mostra a missão e quem está escolhendo a missão
      {11, textoAuxiliar, jogadorAlvo, 160, 125, 480, 240, tonumber('0x'..coresPadrao.textAreaFundo), tonumber('0x'..coresPadrao.textAreaBorda), 0.94, false},
      --do modo exibir, mostra a descrição da missão
      {12, textoAuxiliar, jogadorAlvo, 310, 180, 235, 175, nil, nil, 0, false},
      --do modo exibir, mostra o líder da missão
      {13, textoAuxiliar, jogadorAlvo, 180, 190, 440, 175, nil, nil, 0, false}
  })[i]
  end
end

local removerTextArea = function(numeroDaTextArea, jogadorAlvo, ...) --remove text area
  if ... then --se tem + de 1 textarea pra remover
    local argumentos = {...}
    for i=1, #argumentos do
      ui_removeTextArea(argumentos[i], jogadorAlvo)
    end
  end
    ui_removeTextArea(numeroDaTextArea, jogadorAlvo)
end

local carregarTextArea = function(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra) --carrega textarea
  ui_addTextArea(table_unpack(textAreas(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra)))
  return false
end

--funções úteis (essas não fui eu quem fez, créditos aos criadores obviamente rs)
local shuffle = function(tbl) --embaralhador, coloca a tabela em ordem aleatória
  local t = {}
  for i, v in ipairs(tbl) do
    local pos = math_random(1, #t+1)
    table_insert(t, pos, v)
  end
  return t
end

local string_starts = function(String, Start) --não está sendo usado, verificar se pode remover
   return string_sub(String,1,string_len(Start))==Start
end

local try = function(f, catch_f) --não está sendo usado, verificar se pode remover
  local status, exception = pcall(f) --função "try" igual ao python, n sei se vou usar
  if not status then
    catch_f(exception)
  end
end

local tablelength = function(T) --contar o número de elementos na tabela
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local gradient = function(targetPlayer, force, imagem, camada, opacity) --por sklag#2552, adiciona as imagens em modo degradê
  local y = 0
  local opacity = opacity or 1.08
  local numeroDeImagens = 0
  local imagem = imagem or '17948da3319.png'
  local camada = camada or '!'
  while opacity > 0 do
    y = y +1
    opacity = opacity-force
    numeroDeImagens = numeroDeImagens+1
    tfm_exec_addImage(imagem, camada..'1', 0, y, targetPlayer, 800, 1, nil, opacity)
    tfm_exec_addImage(imagem, camada..'1', 0, 400-y, targetPlayer, 800, 1, nil, opacity)
  end
  return numeroDeImagens
end

--+ tabelas e funções do jogo
for i=1, math_random(32, 128) do
  papeisNoJogo = (shuffle(papeisNoJogo)) --embaralha a tabela "papel" pra definir espião ou sociedade
end

local podeSerAdministrador = function(nomeDoJogador) --lista de pessoas que ganharão 'admin' no jogo automaticamente
  return administradores[nomeDoJogador] == nil and string_sub(nomeDoJogador, -5) == "#0001" or string_sub(nomeDoJogador, -5) == "#0010" or string_sub(nomeDoJogador, -5) == "#0015" or string_sub(nomeDoJogador, -5) == "#0020" or nomeDoJogador == ({pcall(nil)})[2]:match('(.+#%d+)')
end

local analisarJogador = function(nomeDoJogador)
  if jogadoresGlobais[nomeDoJogador] == nil then
    tfm_exec_setPlayerScore(nomeDoJogador, 0)
  else
    tfm_exec_setPlayerScore(nomeDoJogador, jogadoresGlobais[nomeDoJogador])
  end
  system_bindKeyboard(nomeDoJogador, 32, true, true) --espaço
  tfm_exec_respawnPlayer(nomeDoJogador) --ressuscita
  for i=1, 6 do --exibe as textareas sempre q alguém novo entra
    if jogadoresNoJogo[i][2] == 0 and jogadoresNoJogo[i][1] == nomeDoJogador then
      carregarTextArea(i, nomeDoJogador, coresPadrao.espiao)
    else
      if jogadoresNoJogo[i][1] == '</b><font size="11">[ espaço ]' then
        carregarTextArea(i, nomeDoJogador, coresPadrao.corDeEspaco) --"[ espaço ]" se a cadeira tá vazia
      else
        carregarTextArea(i, nomeDoJogador, coresPadrao.brancoDeTexto) --nome se a cadeira tem gente
      end
    end
  end
  if listaDeModos[1].modoAtual then --mostra "faltam x jogadores"
    carregarTextArea(7, nomeDoJogador)
  end
end

local removerDegrade = function(imagensParaRemover)
  for i=1, imagensParaRemover do
    tfm_exec_removeImage(i)
  end
end

--ajustando + coisas

for k in next, tfm.get.room.playerList do
  jogadoresNaSala[#jogadoresNaSala+1] = tfm.get.room.playerList[k].playerName
end


for i=1, #jogadoresNaSala do --executa p'ra todes
  analisarJogador(jogadoresNaSala[i])
end

--tfm.exec.playSound('tfmadv/musique/tfmadv_musique1.mp3')
--coroutine que será chamada pelo eventLoop
local scriptDoGato = coroutine_create(function()
  local degradeParaRemover
  while true do
    if listaDeModos[1].modoAtual and jogadoresTotais == 6 then --cadeira - pegar as cadeiras
      listaDeModos[1].modoAtual = false
      listaDeModos[2].modoAtual = true
      tempoPercorrido = 0
      removerTextArea(listaDeModos[1].textAreaDeTempo, nil)
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[2].modoAtual then --iniciar - mostra sociedade ou espião
      carregarTextArea(listaDeModos[2].textAreaDeTempo, nil, nil, listaDeModos[2].duracaoDoModo) --contagem do tempo
      if listaDeModos[2].primeiraVez then
        degradeParaRemover = gradient(nil, 0.008)
        for i=1, #jogadoresNoJogo do --muda a cor dos espiões para vermelho
        print(jogadoresNoJogo[i][1]..' | '..jogadoresNoJogo[i][2])
          if jogadoresNoJogo[i][2] == 0 then
            for j=1, #jogadoresNoJogo do
              if jogadoresNoJogo[j][2] == 0 then
                carregarTextArea(i, jogadoresNoJogo[j][1], coresPadrao.espiao)
              end
            end --abaixo: mostra a mensagem do espião
              carregarTextArea(11, jogadoresNoJogo[i][1], '<font color="#'..coresPadrao.espiao..'" size="22"><b>&#12288;Você é um espião</b></font>\n\n\n<font size="14" color="#'..coresPadrao.brancoDeTexto..'">&#12288;&#12288;&#12288;➜ <font color="#'..coresPadrao.espiao..'">Infiltre</font> e <font color="#'..coresPadrao.espiao..'">sabote</font> 3 missões da <font color="#'..coresPadrao.sociedade..'">sociedade</font> para vencer;\n\n&#12288;&#12288;&#12288;➜ Seja discreto: não deixe que a <font color="#'..coresPadrao.sociedade..'">sociedade</font> descubra\n&#12288;&#12288;&#12288;&#12288;sua verdadeira <font color="#'..coresPadrao.espiao..'">identidade</font>;\n\n&#12288;&#12288;&#12288;➜ Tente fazer com que o <font color="#'..coresPadrao.lider..'">Líder</font> da missão escolha você.\n&#12288;&#12288;&#12288;&#12288;Um <font color="#'..coresPadrao.espiao..'">espião</font> pode sabotar a missão inteira.</font>')
            else --mostra a mensagem da sociedade
              carregarTextArea(11, jogadoresNoJogo[i][1], '<font color="#'..coresPadrao.sociedade..'" size="22"><b>&#12288;Você é sociedade</b></font>\n\n\n<font size="14" color="#'..coresPadrao.brancoDeTexto..'">&#12288;&#12288;&#12288;➜ Complete <font color="#'..coresPadrao.sociedade..'">3 missões</font> com <font color="#'..coresPadrao.sociedade..'">sucesso</font> para vencer;\n\n&#12288;&#12288;&#12288;➜ Fique atento: há <font color="#'..coresPadrao.espiao..'">2 espiões</font> infiltrados na <font color="#'..coresPadrao.sociedade..'">sociedade</font>\n&#12288;&#12288;&#12288;&#12288;que podem sabotar as missões;\n\n&#12288;&#12288;&#12288;➜ Ao ser o <font color="#'..coresPadrao.lider..'">Líder</font> da missão, escolha com sabedoria\n&#12288;&#12288;&#12288;&#12288;seus agentes. Um <font color="#'..coresPadrao.espiao..'">espião</font> pode sabotar a missão inteira.</font>')
          end
        end
        listaDeModos[2].primeiraVez = false
      end
      if tempoPercorrido == listaDeModos[2].duracaoDoModo then
        if missaoAtual == 1 or missaoAtual == 5 then
          missaoSelecionada = math_random(#listaDeMissoes-3)
        else
          missaoSelecionada = math_random(#listaDeMissoes)
        end
        liderDaMissao = jogadoresNoJogo[math_random(#jogadoresNoJogo)][1]
        removerTextArea(11, nil)
        tempoPercorrido = 0
        listaDeModos[2].modoAtual = false
        listaDeModos[3].modoAtual = true
        coroutine_yield()
      end
      if tempoPercorrido >= listaDeModos[2].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[3].modoAtual then --exibir - missao atual
      carregarTextArea(listaDeModos[3].textAreaDeTempo, nil, nil, listaDeModos[3].duracaoDoModo)
      if listaDeModos[3].primeiraVez then
        numeroDeAgentesNaMissao = sequenciaDaPartida[missaoAtual]
        listaDeModos[3].primeiraVez = false
        carregarTextArea(11, nil, '<font size="16" color="#'..coresPadrao.missaoNumero..'"><b>&#12288;&#12288;Missão #'..tostring(missaoAtual)..'</b></font>\n<font size="22" color="#'..coresPadrao.brancoDeTexto..'"><b>&#12288;&#12288;&#12288; <font size="16" color="#'..coresPadrao.missaoNumero..'"><b>└ </b></font>'..listaDeMissoes[missaoSelecionada][1]..'</b></font>')
        carregarTextArea(12, nil, '<p align="justify"><font size="10" color="#'..coresPadrao.brancoMaisEscuro..'">'..listaDeMissoes[missaoSelecionada][2]..'</font></p>')
      elseif tempoPercorrido == listaDeModos[3].duracaoDoModo/2-2 then
        removerTextArea(12, nil)
      elseif tempoPercorrido == (listaDeModos[3].duracaoDoModo/2)-1 then
        liderGenero = tfm.get.room.playerList[liderDaMissao] and tfm.get.room.playerList[liderDaMissao].gender or 0
        carregarTextArea(13, nil, '\n<font size="14" color="#'..coresPadrao.lider..'"><b>'..liderDaMissao..'</b></font><font size="13" color="#'..coresPadrao.brancoDeTexto..'"> foi escolhido como líder da missão.\n'..pronomes[liderGenero]..' terá que selecionar '..numeroDeAgentesNaMissao..' agentes para completar a missão.\n\n\n\n\n\n\n\n<p align="right"><font size="11">'..mensagemAleatoria[math_random(#mensagemAleatoria)]..'</font></p></font>')
      elseif tempoPercorrido == listaDeModos[3].duracaoDoModo then
        removerTextArea(11, nil, 13)
        tempoPercorrido = 0
        listaDeModos[3].modoAtual = false
        listaDeModos[4].modoAtual = true
      elseif tempoPercorrido >= listaDeModos[3].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[4].modoAtual then --selecionar - seleciona os agentes da missão
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[5].modoAtual then
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[6].modoAtual then
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[7].modoAtual then
    ------------------------------------------------------------------------------------------
    end

    coroutine_yield()
  end
end)

---------------------------------------------------------
do 
  local aCada1Segundo
  eventLoop = function() --"aii mimimi coroutine desnecessaria" AAAAAAAAA RASENGAN
    if aCada1Segundo then 
      aCada1Segundo = false
      return
    end
    if coroutine_resume(scriptDoGato) == false then
      gradient(nil, 0.008, '17948d9ecc2.png', ':', 0.98)
      for i=1, 3 do
        removerTextArea(10+i)
      end
      carregarTextArea(10, nil)
      coroutine_resume = function() return true end
    end
    tempoPercorrido = tempoPercorrido+1
    aCada1Segundo = true
  end
end

eventNewPlayer = function(jogadorQueEntrou)
  analisarJogador(jogadorQueEntrou)
end

local sala = {'Preuclides#3383', 'Sklag#2552', 'Helsey#6880', 'Momomorrow#0000', 'Descont_o#0000', 'Eletroohause#0000'}
eventKeyboard = function(nomeDoJogador, teclaPressionada, _, posicaoXDoRato)
   --padrão: jogadores={{Falado#0000, 0}, [Fulano#0000, 1]}
  if teclaPressionada == 32 and listaDeModos[1].modoAtual then --cá temos cada textarea das cadeiras, tb coloca os jogadores na tabela {jogadores}
    for i=1, 6 do
      if jogadoresNoJogo[i][1] == nomeDoJogador then return end --quem já tem cadeira não pode pegar outra
      nomeDoJogador = sala[i] --apenas para teste
      posicaoXDoRato = 30-140+(i*140) --teste também, remover depois
      if posicaoXDoRato > 25-140+i*140 and posicaoXDoRato < 75-140+i*140 and jogadoresNoJogo[i][1] == '</b><font size="11">[ espaço ]' then --verifica se o posicaoXDoRato do jogador é em cima de uma cadeira
        jogadoresNoJogo[i] = {nomeDoJogador, papeisNoJogo[i]}; carregarTextArea(i, nil, coresPadrao.brancoDeTexto); jogadoresTotais = jogadoresTotais+1; --loadTextArea(7) --insere txtareas
      end
    end --tirar popup depois
    --ui.addPopup(3, 0, jogadoresNoJogo[1][1]..' : '..jogadoresNoJogo[1][2]..'\n'..jogadoresNoJogo[2][1]..' : '..jogadoresNoJogo[2][2]..'\n'..jogadoresNoJogo[3][1]..' : '..jogadoresNoJogo[3][2]..'\n'..jogadoresNoJogo[4][1]..' : '..jogadoresNoJogo[4][2]..'\n'..jogadoresNoJogo[5][1]..' : '..jogadoresNoJogo[5][2]..'\n'..jogadoresNoJogo[6][1]..' : '..jogadoresNoJogo[6][2]..'\n', nil, 575, 55, 200, false)
  end
end

--mapa
do
  local mapaXML = [[<C><P /><Z><S><S P="0,0,0.3,0.2,0,0,0,0" L="800" o="2e2825" H="210" Y="236" T="12" X="400" /><S P="0,0,0.3,0.2,0,0,0,0" L="800" o="0" X="400" c="3" Y="370" T="12" H="60" /><S H="50" L="1600" o="0" X="400" c="3" Y="117" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S H="3000" L="200" o="6a7495" X="900" c="4" N="" Y="646" T="12" P="0,0,0,0.2,0,0,0,0" /><S P="0,0,0,0.2,0,0,0,0" L="200" o="6a7495" X="-100" c="4" N="" Y="183" T="12" H="3000" /><S P="0,0,0,0.2,0,0,0,0" L="800" o="6a7495" X="400" c="4" N="" Y="-50" T="12" H="100" /><S P="0,0,0,9999,0,0,0,0" L="10" o="324650" H="265" Y="32" T="12" X="900" /><S L="10" o="324650" H="265" X="-100" Y="32" T="12" P="0,0,0,9999,0,0,0,0" /><S P="0,0,0.3,0.2,180,0,0,0" L="3000" o="3488" X="600" c="2" Y="1500" T="12" m="" H="3000" /><S P="0,0,0,0.2,0,0,0,0" L="200" o="6a7495" X="1100" c="4" N="" Y="674" T="12" H="3000" /><S H="3000" L="200" o="6a7495" X="-300" c="4" N="" Y="159" T="12" P="0,0,0,0.2,0,0,0,0" /></S><D><P C="262626,4a2d10" Y="0" T="117" X="0" P="0,0" /><P C="7f7f7f" Y="110" T="96" X="400" P="0,0" /><P X="260" Y="51" T="112" P="0,0" /><P X="0" Y="148" T="17" P="0,0" /><P P="0,0" Y="148" T="17" X="100" /><P X="200" Y="148" T="17" P="0,0" /><P P="0,0" Y="148" T="17" X="300" /><P C="df2d00" Y="116" T="19" X="50" P="0,0" /><P X="400" Y="148" T="17" P="0,0" /><P C="df2d00" Y="116" T="19" X="190" P="0,0" /><P C="df2d00" Y="116" T="19" P="0,0" X="330" /><P P="0,0" Y="148" T="17" X="500" /><P X="600" Y="148" T="17" P="0,0" /><P C="df2d00" Y="116" T="19" X="470" P="0,0" /><P P="0,0" Y="148" T="17" X="700" /><P C="df2d00" Y="116" T="19" P="0,0" X="610" /><P X="800" Y="148" T="17" P="0,0" /><P C="df2d00" Y="116" T="19" P="0,0" X="750" /><DS Y="82" X="400" /><P P="0,0" Y="148" T="17" X="-100" /><P P="0,0" Y="148" T="17" X="900" /><P X="661" Y="93" T="55" P="0,0" /></D><O /></Z></C>]]
  tfm_exec_newGame(mapaXML)
end
