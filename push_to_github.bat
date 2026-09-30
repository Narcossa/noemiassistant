@echo off
echo ========================================================
echo Envoi du code NoemiAssistant vers GitHub...
echo ========================================================
echo Une fenetre va vous demander de vous connecter a GitHub.
echo Cliquez sur "Sign in with your browser".
echo.
git push -u origin main
echo.
echo ========================================================
echo Si tout est termine, appuyez sur une touche pour fermer.
pause > nul
